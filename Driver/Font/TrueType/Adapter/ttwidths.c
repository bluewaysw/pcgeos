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
#include "ttacache.h"
#include "ttcharmapper.h"
#include "ttmemory.h"
#include "ttinit.h"
#include "freetype.h"
#include "ftxkern.h"


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
                        TextStyle               styleToImplement,
                        Byte                    width,
                        Byte                    weight );

static void CalcTransform( 
                        TransformMatrix*        transMatrix,
                        FontMatrix*             fontMatrix, 
                        FontBuf*                fontBuf,
                        TextStyle               stylesToImplement,
                        Byte                    width,
                        Byte                    weight );

static void AdjustFontBuf( TransformMatrix*     transMatrix, 
                        FontMatrix*             fontMatrix, 
                        FontBuf*                fontBuf );

static Boolean IsRegionNeeded( TransformMatrix* transMatrix, 
                        FontBuf*                fontBuf );

extern void InitConvertHeader( TRUETYPE_VARS, FontHeader* fontHeader );

static void FillKerningFlags( FontHeader* fontHeader, FontBuf* fontBuf );


#define ROUND_WWFIXED( value )    ( value & 0xffff ? ( value >> 16 ) + 1 : value >> 16 )

#define ROUND_WBFIXED( value )    ( value.WBF_frac ? ( value.WBF_int + 1 ) : value.WBF_int )

#define OFFSET_KERN_PAIRS         ( sizeof(FontBuf) +                                   \
                                    fontHeader->FH_numChars * sizeof( CharTableEntry) + \
                                    sizeof( TransformMatrix ) )

#define OFFSET_KERN_VALUES        ( sizeof(FontBuf) +                                   \
                                    fontHeader->FH_numChars * sizeof( CharTableEntry) + \
                                    sizeof( TransformMatrix ) +                         \
                                    fontHeader->FH_kernCount * sizeof( KernPair ) )


/********************************************************************
 *                      TrueType_Gen_Widths
 ********************************************************************
 * SYNOPSIS:       Generates the widths for a TrueType font, creating 
 *                 a FontBuf structure with various character metrics.
 * 
 * PARAMETERS:     MemHandle fontHandle
 *                    Handle to a memory block that stores font information.
 *                 FontMatrix* fontMatrix
 *                    Transformation matrix for the font.
 *                 WWFixedAsDWord pointSize
 *                    The size of the font in points.
 *                 Byte width
 *                    Width parameter to be applied to the font.
 *                 Byte weight
 *                    Weight parameter to be applied to the font.
 *                 const FontInfo* fontInfo
 *                    Font information describing the TrueType font.
 *                 const OutlineEntry* headerEntry
 *                    Entry describing the TrueType outline information.
 *                 const OutlineEntry* firstEntry
 *                    Entry describing the TrueType header information.
 *                 TextStyle stylesToImplement
 *                    Styles such as bold or italic to be implemented.
 *                 MemHandle varBlock
 *                    Handle to a memory block with TrueType-specific variables.
 * 
 * RETURNS:        MemHandle
 *                    A handle to the memory block containing font block.
 * 
 * STRATEGY:       - Validates all input handles and pointers.
 *                 - Locks and dereferences the TrueType variables, font information, 
 *                   and outline entries.
 *                 - Opens the TrueType face and initializes the conversion header.
 *                 - Allocates the memory block for `FontBuf`, including character 
 *                   entries, kerning pairs, and kerning values.
 *                 - Initializes fields in `FontBuf` that are not scale-dependent.
 *                 - Calculates the scale factor and fills `FontBuf` with the converted 
 *                   header, widths, and kerning information.
 *                 - Calculates the transformation matrix and adjusts the final 
 *                   metrics for `FontBuf`.
 *                 - Determines if the glyphs are rendered as regions and adjusts 
 *                   flags accordingly.
 *                 - Unlocks the TrueType face and returns the updated `fontHandle`.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20.12.22  JK        Initial Revision
 *      11.02.24  JK        width and weight implemented
 *******************************************************************/

MemHandle _pascal TrueType_Gen_Widths(
                        MemHandle            fontHandle,
                        FontMatrix*          fontMatrix,
                        WWFixedAsDWord       pointSize,
                        Byte                 width,
                        Byte                 weight,
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
	TrueTypeCacheBufSpec   bufSpec;

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

	InitConvertHeader( trueTypeVars, fontHeader );

        /* alloc Block for FontBuf, CharTableEntries, KernPairs and kerning values */
	bufSpec.TTCBS_pointSize = pointSize;
	bufSpec.TTCBS_width = width;
	bufSpec.TTCBS_weight = weight;
	bufSpec.TTCBS_stylesToImplement = stylesToImplement;

	if((fontMatrix->FM_flags & TF_COMPLEX) || !TrueType_Cache_LoadFontBlock(
		trueTypeVars->cacheFile, trueTypeVars->entry.TTOE_fontFileName, &bufSpec,
		&fontHandle		
	)) {
		size = AllocFontBlock( sizeof( TransformMatrix ), 
				fontHeader->FH_numChars, 
				fontHeader->FH_kernCount, 
				&fontHandle );
		fontBuf = (FontBuf*)MemDeref( fontHandle );
EC(     	ECCheckBounds( (void*) fontBuf ) );

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
		CalcScaleForWidths( trueTypeVars, pointSize, stylesToImplement, width, weight );

		/* convert FontHeader and fill FontBuf structure */
		ConvertHeader( trueTypeVars, fontHeader, fontBuf );

		/* fill kerning pairs and kerning values */
		ConvertKernPairs( trueTypeVars, fontBuf );

		/* convert widths and fill CharTableEntries */
		ConvertWidths( trueTypeVars, fontHeader, fontBuf );

		/* FIXME: We are temporarily disabling support for kerning as this causes instability in the driver. */
		FillKerningFlags( fontHeader, fontBuf ); 

		/* calculate the transformation matrix and copy it into the FontBlock */
		transMatrix = (TransformMatrix*)(((byte*)fontBuf) + sizeof( FontBuf ) + fontHeader->FH_numChars * sizeof( CharTableEntry ));
EC(     	ECCheckBounds( (void*)transMatrix ) );
		CalcTransform( transMatrix, fontMatrix, fontBuf, stylesToImplement, width, weight );

		/* adjust FB_height, FB_minTSB, FB_pixHeight and FB_baselinePos */
		AdjustFontBuf( transMatrix, fontMatrix, fontBuf );

		/* Are the glyphs rendered as regions? */
		if( IsRegionNeeded( transMatrix, fontBuf ) )
			fontBuf->FB_flags |= FBF_IS_REGION;

		if( !(fontMatrix->FM_flags & TF_COMPLEX) ) {
			
			TrueType_Cache_UpdateFontBlock(
				trueTypeVars->cacheFile,
				trueTypeVars->entry.TTOE_fontFileName, 
				&bufSpec, fontHandle		
			);		
		}
	}
	TrueType_Unlock_Face( trueTypeVars );
Fail:        
	MemUnlock( varBlock );

        return fontHandle;
}


/********************************************************************
 *                      ConvertWidths
 ********************************************************************
 * SYNOPSIS:       Converts character width information from a TrueType
 *                 font header and populates the provided font buffer
 *                 with the computed metrics for each character.
 * 
 * PARAMETERS:     TRUETYPE_VARS
 *                    Cached variables needed by the TrueType driver.
 * 
 *                 FontHeader* fontHeader
 *                    Pointer to the FontHeader structure, containing
 *                    metadata about the character set, such as the
 *                    range of characters.
 * 
 *                 FontBuf* fontBuf
 *                    Pointer to the FontBuf structure that will be filled
 *                    with character metrics and other data.
 * 
 * RETURNS:        void
 * 
 * STRATEGY:       - Iterate over each character defined in the FontHeader.
 *                 - For each character, determine the corresponding glyph
 *                   index using the character map.
 *                 - If the character is not mapped, mark it as having no
 *                   data and continue to the next character.
 *                 - Load the glyph metrics and compute the scaled width.
 *                 - Populate each CharTableEntry with the computed width
 *                   and relevant flags based on glyph bounding box values.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      12.02.23  JK        Initial Revision
 *      17.09.24  JK        filling kern pairs moved to separate function
 *******************************************************************/

static void ConvertWidths( TRUETYPE_VARS, FontHeader* fontHeader, FontBuf* fontBuf )
{
        word             currentChar;
        CharTableEntry*  charTableEntry = (CharTableEntry*) (((byte*)fontBuf) + sizeof( FontBuf ));
        WWFixedAsDWord   scaledWidth;


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
                }
                else
                {
                        /* load metrics */
                        TT_Get_Index_Metrics( FACE, charIndex, &GLYPH_METRICS );

                        /* fill CharTableEntry */
                        scaledWidth = GrMulWWFixed( MakeWWFixed( GLYPH_METRICS.advance), SCALE_WIDTH );
                        charTableEntry->CTE_width.WBF_int  = INTEGER_OF_WWFIXEDASDWORD( scaledWidth );
                        charTableEntry->CTE_width.WBF_frac = FRACTION_OF_WWFIXEDASDWORD( scaledWidth );
                        charTableEntry->CTE_dataOffset     = CHAR_NOT_BUILT;
                        charTableEntry->CTE_usage          = 0;
                        charTableEntry->CTE_flags          = 0;
                
               
                        /* set flags in CTE_flags if needed */
                        if( GLYPH_BBOX.xMin < 0 )
                                charTableEntry->CTE_flags |= CTF_NEGATIVE_LSB;
                        
                        if( -GLYPH_BBOX.yMin > fontHeader->FH_descent )
                                charTableEntry->CTE_flags |= CTF_BELOW_DESCENT;

                        if( GLYPH_BBOX.yMax > fontHeader->FH_ascent )
                                charTableEntry->CTE_flags |= CTF_ABOVE_ASCENT;
                }

                ++charTableEntry;
        } 
}


/********************************************************************
 *                      FillKerningFlags
 ********************************************************************
 * SYNOPSIS:       Updates the character table entries in the font
 *                 buffer to indicate which characters are involved
 *                 in kerning pairs.
 * 
 * PARAMETERS:     FontHeader* fontHeader
 *                    Pointer to the FontHeader structure containing
 *                    metadata about the character set.
 * 
 *                 FontBuf* fontBuf
 *                    Pointer to the FontBuf structure, which contains
 *                    character table entries and kerning pair information.
 * 
 * RETURNS:        void
 * 
 * STRATEGY:       - Retrieve the kerning pairs and character table entries
 *                   from the font buffer.
 *                 - Iterate over each kerning pair to find the left and
 *                   right characters involved.
 *                 - Set the appropriate flags (`CTF_IS_FIRST_KERN` and
 *                   `CTF_IS_SECOND_KERN`) in the corresponding character
 *                   table entries.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      18.09.24  JK        Initial Revision
 *******************************************************************/

static void FillKerningFlags( FontHeader* fontHeader, FontBuf* fontBuf ) 
{
        word             i;
        const KernPair*  const kernPairs = (const KernPair*) ( ( (const byte*)fontBuf ) + fontBuf->FB_kernPairs );
        CharTableEntry*  const charTableEntries = (CharTableEntry*) ( ( (byte*)fontBuf ) + sizeof( FontBuf ));

EC(     ECCheckStack() );
EC(     ECCheckBounds( (void*)kernPairs ) );
EC(     ECCheckBounds( charTableEntries ) );

        for( i = 0; i < fontBuf->FB_kernCount; ++i )
        {
                const unsigned char  indexLeftChar  = kernPairs[i].KP_charLeft - fontHeader->FH_firstChar;
                const unsigned char  indexRightChar = kernPairs[i].KP_charRight - fontHeader->FH_firstChar;


EC_ERROR_IF(    indexLeftChar  > fontHeader->FH_lastChar - fontHeader->FH_firstChar, CHARINDEX_OUT_OF_BOUNDS );
EC_ERROR_IF(    indexRightChar > fontHeader->FH_lastChar - fontHeader->FH_firstChar, CHARINDEX_OUT_OF_BOUNDS );

                charTableEntries[indexLeftChar].CTE_flags  |= CTF_IS_FIRST_KERN;
                charTableEntries[indexRightChar].CTE_flags |= CTF_IS_SECOND_KERN;
        }
}


/********************************************************************
 *                      ConvertKernPairs
 ********************************************************************
 * SYNOPSIS:       Converts the kerning pairs for a TrueType font, 
 *                 filling the FontBuf structure with kerning information.
 * 
 * PARAMETERS:     TRUETYPE_VARS
 *                    Cached variables needed by the TrueType driver.
 *                 FontBuf* fontBuf
 *                    Pointer to the FontBuf structure where the converted 
 *                    kerning pairs and values are stored.
 * 
 * RETURNS:        void
 * 
 * STRATEGY:       - Validates the `kernPair` and `kernValue` pointers.
 *                 - Loads the kerning directory of the TrueType font.
 *                 - Locks the lookup table to obtain glyph indices.
 *                 - Iterates through the kerning tables, specifically 
 *                   searching for format 0 kerning subtables.
 *                 - Loads each valid kerning subtable and iterates through 
 *                   the kerning pairs.
 *                 - Extracts the kerning pair values and character indices.
 *                 - Filters pairs based on a minimum kerning value and 
 *                   converts them into the `KernPair` and `BBFixed` structures.
 *                 - Unlocks resources such as the kerning pairs block 
 *                   and lookup table after use.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20.12.22  JK        Initial Revision
 *******************************************************************/

static void ConvertKernPairs( TRUETYPE_VARS, FontBuf* fontBuf )
{
        TT_Kerning        kerningDir;
        word              table;
        TT_Kern_0_Pair*   pairs;
        LookupEntry*      indices;
	word		  kernCount = 0;
        

        KernPair*  kernPair  = (KernPair*) ( ( (byte*)fontBuf ) + fontBuf->FB_kernPairs );
        BBFixed*   kernValue = (BBFixed*) ( ( (byte*)fontBuf ) + fontBuf->FB_kernValues );


EC(     ECCheckBounds( (void*)kernPair ) );
EC(     ECCheckBounds( (void*)kernValue ) );

        /* load kerning directory */
        if( TT_Get_Kerning_Directory( FACE, &kerningDir ) )
                return;

        if( kerningDir.nTables == 0 )
                return;

        /* get pointer to lookup table */
        indices = GEO_LOCK( LOOKUP_TABLE );
EC(     ECCheckBounds( indices ) );

        /* search for format 0 subtable */
        for( table = 0; table < kerningDir.nTables; ++table )
        {
                word        i;
                const word  minKernValue = UNITS_PER_EM / KERN_VALUE_DIVIDENT;
                

                if( TT_Load_Kerning_Table( FACE, table ) )
                        continue;

                if( kerningDir.tables->format != 0 )
                        continue;

                pairs = GEO_LOCK( kerningDir.tables->t.kern0.pairsBlock );
EC(             ECCheckBounds( pairs ) );

                for( i = 0; i < kerningDir.tables->t.kern0.nPairs; ++i )
                {
                        const char left = GetGEOSCharForIndex( indices, pairs[i].left );
                        const char right = GetGEOSCharForIndex( indices, pairs[i].right );

                        if( left && right && ABS( pairs[i].value ) > minKernValue )
                        {
                                WWFixedAsDWord  scaledKernValue;


                                kernPair->KP_charLeft  = left;
                                kernPair->KP_charRight = right;

                                /* save scaled kerning value */
                                scaledKernValue = SCALE_WORD( pairs[i].value, SCALE_WIDTH );
                                kernValue->BBF_int = IntegerOf( scaledKernValue );
                                kernValue->BBF_frac = FractionOf( scaledKernValue ) >> 8;

                                ++kernPair;
                                ++kernValue;

				kernCount++;
                        }
                }
                GEO_UNLOCK( kerningDir.tables->t.kern0.pairsBlock );
        }
	EC_ERROR_IF(kernCount != fontBuf->FB_kernCount, -1);
        GEO_UNLOCK( LOOKUP_TABLE );
}


/********************************************************************
 *                      CalcScaleForWidths
 ********************************************************************
 * SYNOPSIS:       Calculates the scaling factors for the width and height
 *                 of a TrueType font, adjusting them based on various
 *                 styles and parameters.
 * 
 * PARAMETERS:     TRUETYPE_VARS
 *                    Cached variables needed by the TrueType driver.
 *                 WWFixedAsDWord pointSize
 *                    The desired point size for the font.
 *                 TextStyle stylesToImplement
 *                    The text styles that need to be implemented, such as
 *                    bold, subscript, or superscript.
 *                 Byte width
 *                    The desired width scaling factor, indicating if the 
 *                    font should be wider or narrower.
 *                 Byte weight
 *                    The desired weight scaling factor, for adjusting
 *                    the font weight (e.g., normal or bold).
 * 
 * RETURNS:        void
 * 
 * STRATEGY:       - Calculate the initial height scaling factor (`SCALE_HEIGHT`)
 *                   using the given point size and the font's units per EM.
 *                 - Initialize `SCALE_WIDTH` to match `SCALE_HEIGHT` initially.
 *                 - Adjust `SCALE_WIDTH` if the bold style (`TS_BOLD`) is present,
 *                   scaling it slightly wider by a factor of `1.1`.
 *                 - Further adjust `SCALE_WIDTH` if subscript or superscript
 *                   styles (`TS_SUBSCRIPT` or `TS_SUPERSCRIPT`) are specified, 
 *                   reducing it by half.
 *                 - Implement additional scaling for width and weight if they
 *                   are different from the default values (`FWI_MEDIUM` and 
 *                   `FW_NORMAL` respectively), applying corresponding scaling 
 *                   multipliers.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20.12.22  JK        Initial Revision
 *      10.02.24  JK        width and weight implemented
 *******************************************************************/

static void CalcScaleForWidths( TRUETYPE_VARS, 
                                WWFixedAsDWord  pointSize, 
                                TextStyle       stylesToImplement,
                                Byte            width,
                                Byte            weight )
{
        SCALE_HEIGHT = GrUDivWWFixed( pointSize, MakeWWFixed( FACE_PROPERTIES.header->Units_Per_EM ) );
        SCALE_WIDTH  = SCALE_HEIGHT;

        if( stylesToImplement & ( TS_BOLD ) )
                SCALE_WIDTH = GrMulWWFixed( SCALE_HEIGHT, WWFIXED_1_POINR_1 );

        if( stylesToImplement & ( TS_SUBSCRIPT | TS_SUPERSCRIPT ) )     
                SCALE_WIDTH = GrMulWWFixed( SCALE_WIDTH, WWFIXED_0_POINT_5 );

        /* implement width and weight */
        if( width != FWI_MEDIUM )
                SCALE_WIDTH = MUL_100_WWFIXED( SCALE_WIDTH, width );

        if( weight != FW_NORMAL )
                SCALE_WIDTH = MUL_100_WWFIXED( SCALE_WIDTH, weight );
}


/********************************************************************
 *                      CalcTransform
 ********************************************************************
 * SYNOPSIS:       Calculates the transformation matrix for rendering 
 *                 text based on the font properties, styles to be 
 *                 applied, and additional transformations specified 
 *                 by the `FontMatrix`.
 * 
 * PARAMETERS:     TransformMatrix* transMatrix
 *                    Pointer to the transformation matrix where the
 *                    resulting transformations are stored.
 *                 FontMatrix* fontMatrix
 *                    Pointer to the font transformation matrix containing
 *                    scaling and transformation properties.
 *                 FontBuf* fontBuf
 *                    Pointer to `FontBuf` containing various font metrics.
 *                 TextStyle stylesToImplement
 *                    Specifies the styles to be applied to the text, 
 *                    such as bold, italic, subscript, or superscript.
 *                 Byte width
 *                    Specifies the width modification factor for the font.
 *                 Byte weight
 *                    Specifies the weight modification factor for the font.
 * 
 * RETURNS:        void
 * 
 * STRATEGY:       - The function begins by initializing the transformation
 *                   matrix (`tempMatrix`) to a default identity matrix.
 *                 - The `transMatrix` values (`TM_heightX`, `TM_scriptX`, 
 *                   `TM_heightY`, `TM_scriptY`) are initially set to zero.
 *                 - If the bold style is requested (`TS_BOLD`), the width
 *                   scaling factor (`tempMatrix.xx`) is modified by the 
 *                   `BOLD_FACTOR`.
 *                 - For italic style (`TS_ITALIC`), a shear transformation
 *                   (`tempMatrix.yx`) is applied using `NEGATIVE_ITALIC_FACTOR`.
 *                 - Width and weight adjustments are applied to the scaling 
 *                   matrix.
 *                 - If subscript or superscript styles (`TS_SUBSCRIPT` or 
 *                   `TS_SUPERSCRIPT`) are required, additional scaling and 
 *                   script offset calculations are performed.
 *                   - The script offset is computed based on the font height
 *                     and height adjustments.
 *                   - Subscript and superscript styles are handled separately,
 *                     and script positions are adjusted accordingly.
 *                 - Finally, the `FontMatrix` transformation values are
 *                   integrated into `transMatrix`.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20.12.22  JK        Initial Revision
 *      10.02.24  JK        width and weight implemented
 *******************************************************************/

static void CalcTransform( TransformMatrix*  transMatrix, 
                           FontMatrix*       fontMatrix, 
                           FontBuf*          fontBuf,
                           TextStyle         stylesToImplement,
                           Byte              width,
                           Byte              weight )
{
        TT_Matrix  styleMatrix = { 1L<<16, 0, 0, 1L<<16 };


EC(     ECCheckBounds( (void*)transMatrix ) );
EC(     ECCheckBounds( (void*)fontMatrix ) );
EC(     ECCheckBounds( (void*)fontBuf ) );

        /* initialize transMatrix */
        transMatrix->TM_heightX = 0;
        transMatrix->TM_scriptX = 0;
        transMatrix->TM_heightY = 0;
        transMatrix->TM_scriptY = 0;

        /* fake bold style       */
        if( stylesToImplement & TS_BOLD )
                styleMatrix.xx = BOLD_FACTOR;

        /* fake italic style       */
        if( stylesToImplement & TS_ITALIC )
                styleMatrix.xy = ITALIC_FACTOR;

        /* width and weight */
        if( width != FWI_MEDIUM )
                styleMatrix.xx = MUL_100_WWFIXED( styleMatrix.xx, width );

        if( weight != FW_NORMAL )
                styleMatrix.xx = MUL_100_WWFIXED( styleMatrix.xx, weight );

        /* fake script style      */
        if( stylesToImplement & ( TS_SUBSCRIPT | TS_SUPERSCRIPT ) )
        {      
                WWFixedAsDWord scriptOffset = WBFIXED_TO_WWFIXEDASDWORD( fontBuf->FB_height ) + 
                                              WBFIXED_TO_WWFIXEDASDWORD( fontBuf->FB_heightAdjust );


                styleMatrix.xx = GrMulWWFixed( styleMatrix.xx, SCRIPT_FACTOR );
                styleMatrix.yy = GrMulWWFixed( styleMatrix.yy, SCRIPT_FACTOR );

                if( stylesToImplement & TS_SUBSCRIPT )
                {
                        //TODO: Is rounding necessary here?
                        transMatrix->TM_scriptY = GrMulWWFixed( scriptOffset, SUBSCRIPT_OFFSET ) >> 16;
                }
                else
                {
                        //TODO: Is rounding necessary here?
                        transMatrix->TM_scriptY = ( GrMulWWFixed( scriptOffset, SUPERSCRIPT_OFFSET) -
                                                WBFIXED_TO_WWFIXEDASDWORD( fontBuf->FB_baselinePos ) -
                                                WBFIXED_TO_WWFIXEDASDWORD( fontBuf->FB_baseAdjust ) ) >> 16;
                }
        }

        transMatrix->TM_matrix.xx = GrMulWWFixed( styleMatrix.xx, fontMatrix->FM_11 );
        transMatrix->TM_matrix.yx = 0;
        transMatrix->TM_matrix.xy = GrMulWWFixed( styleMatrix.xy, fontMatrix->FM_11 );
        transMatrix->TM_matrix.yy = GrMulWWFixed( styleMatrix.yy, fontMatrix->FM_22 );

        if( fontMatrix->FM_flags & TF_ROTATED )
        {
                TT_Fixed  xy, yx;


                xy = - ( GrMulWWFixed( styleMatrix.yy, fontMatrix->FM_21 ) );
                yx = - ( GrMulWWFixed( styleMatrix.xx, fontMatrix->FM_12 ) +
                         GrMulWWFixed( styleMatrix.xy, fontMatrix->FM_22 ) );

                transMatrix->TM_matrix.xy = xy;
                transMatrix->TM_matrix.yx = yx;
        }
}


/********************************************************************
 *                      AllocFontBlock
 ********************************************************************
 * SYNOPSIS:       Allocates or reallocates a memory block for font data,
 *                 including character entries, kerning pairs, and additional
 *                 buffer space.
 * 
 * PARAMETERS:     word additionalSpace
 *                    Extra memory required beyond the standard font data.
 * 
 *                 word numOfCharacters
 *                    The number of character table entries needed.
 * 
 *                 word numOfKernPairs
 *                    The number of kerning pairs to be stored.
 * 
 *                 MemHandle* fontHandle
 *                    Pointer to a memory handle for the font block. If the
 *                    handle is `NullHandle`, a new block will be allocated.
 * 
 * RETURNS:        word
 *                    The total size of the allocated or reallocated memory block.
 * 
 * STRATEGY:       - Calculate the total memory size needed for the font buffer,
 *                   character table entries, kerning pairs, and additional space.
 *                 - If `fontHandle` is `NullHandle`, allocate a new memory block.
 *                   Otherwise, reallocate the existing block to the required size.
 *                 - Use error-checking macros to ensure that memory allocation
 *                   or reallocation succeeds.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      14.01.23  JK        Initial Revision
 *******************************************************************/

static word AllocFontBlock( word        additionalSpace,
                            word        numOfCharacters,
                            word        numOfKernPairs,
                            MemHandle*  fontHandle )
{
        const word  size = sizeof( FontBuf ) + numOfCharacters * sizeof( CharTableEntry ) +
                numOfKernPairs * ( sizeof( KernPair ) + sizeof( BBFixed ) ) +
                additionalSpace; 
                     
        /* allocate memory for FontBuf, CharTableEntries, KernPairs and additional space */
        if( *fontHandle == NullHandle )
        {
                *fontHandle = MemAllocSetOwner( FONT_MAN_ID, size, 
                        HF_SWAPABLE | HF_SHARABLE | HF_DISCARDABLE,
                        HAF_NO_ERR | HAF_LOCK | HAF_ZERO_INIT );
EC(             ECCheckMemHandle( *fontHandle ) );
                HandleP( *fontHandle );
        }
        else
        {
                MemReAlloc( *fontHandle, size, HAF_NO_ERR | HAF_LOCK );
EC(             ECCheckMemHandle( *fontHandle ) );
        }

        return size;
}


/********************************************************************
 *                      ConvertHeader
 ********************************************************************
 * SYNOPSIS:       Converts and scales a TrueType font header to the 
 *                 internal `FontBuf` structure, adjusting values for 
 *                 rendering.
 * 
 * PARAMETERS:     TRUETYPE_VARS
 *                    Cached variables needed by the TrueType driver.
 *                 FontHeader* fontHeader
 *                    Pointer to the source TrueType `FontHeader`, which
 *                    contains font metrics to be scaled.
 *                 FontBuf* fontBuf
 *                    Pointer to the destination `FontBuf`, which stores
 *                    the converted and scaled metrics for use in rendering.
 * 
 * RETURNS:        void
 * 
 * STRATEGY:       - This function reads font metrics from `fontHeader`, scales
 *                   them using previously calculated scaling factors (`SCALE_WIDTH`
 *                   and `SCALE_HEIGHT`), and writes the results to `fontBuf`.
 *                 - For each font metric (like `average width`, `height`, etc.), 
 *                   the scaling is applied using `SCALE_WORD`, and the result 
 *                   is then split into integer and fractional parts.
 *                 - Several font metrics, such as `baseline position`, 
 *                   `underline position`, and `strike-through position`, are 
 *                   calculated with specific adjustments to ensure visual accuracy.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      11.12.22  JK        Initial Revision
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
 * SYNOPSIS:       Adjusts the transformation and metrics of a font
 *                 buffer (`FontBuf`) to account for scaling, rotation, 
 *                 and other transformations based on the given 
 *                 transformation matrix (`TransformMatrix`) and 
 *                 font transformation properties (`FontMatrix`).
 * 
 * PARAMETERS:     TransformMatrix* transMatrix
 *                    Pointer to the transformation matrix that holds
 *                    scaling and translation values for the font.
 *                 FontMatrix* fontMatrix
 *                    Pointer to the font matrix, which includes the
 *                    transformation flags and scaling factors to be
 *                    applied to the font.
 *                 FontBuf* fontBuf
 *                    Pointer to the `FontBuf` that holds the final
 *                    font metrics, which will be adjusted for rendering.
 * 
 * RETURNS:        void
 * 
 * STRATEGY:       - The function adjusts font metrics and transformation
 *                   values based on whether complex transformations
 *                   (e.g., scaling, rotation) are applied.
 *                 - The initial height (`TM_heightY`) is set based on
 *                   the baseline position with a correction factor
 *                   (`BASELINE_CORRECTION`).
 *                 - If the `FontMatrix` flags indicate a complex 
 *                   transformation (`TF_COMPLEX`), additional scaling and 
 *                   adjustments are applied to various metrics.
 *                 - For rotated fonts, horizontal transformations 
 *                   (`TM_scriptX`, `TM_heightX`) are also adjusted to
 *                   account for the rotation.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      22.07.23  JK        Initial Revision
 *******************************************************************/

static void AdjustFontBuf( TransformMatrix* transMatrix, 
                           FontMatrix*      fontMatrix,         
                           FontBuf*         fontBuf )
{
        transMatrix->TM_heightY = fontBuf->FB_baselinePos.WBF_int + BASELINE_CORRECTION;

        /* transformation if rotated or scaled */
        if( fontMatrix->FM_flags & TF_COMPLEX )
        {
                sword savedScriptY = transMatrix->TM_scriptY;


                fontBuf->FB_flags     |= FBF_IS_COMPLEX;

                transMatrix->TM_heightY = INTEGER_OF_WWFIXEDASDWORD( GrMulWWFixed( 
                                                WORD_TO_WWFIXEDASDWORD( transMatrix->TM_heightY ), fontMatrix->FM_22 ) );
                transMatrix->TM_scriptY = INTEGER_OF_WWFIXEDASDWORD( GrMulWWFixed( 
                                                WORD_TO_WWFIXEDASDWORD( transMatrix->TM_scriptY ), fontMatrix->FM_22 ) );
                            
                /* adjust FB_pixHeight, FB_minTSB */
                fontBuf->FB_pixHeight = INTEGER_OF_WWFIXEDASDWORD( GrMulWWFixed( 
                                                WORD_TO_WWFIXEDASDWORD( fontBuf->FB_height.WBF_int ), fontMatrix->FM_22 ) );
                fontBuf->FB_minTSB    = INTEGER_OF_WWFIXEDASDWORD( GrMulWWFixed( 
                                                WORD_TO_WWFIXEDASDWORD( fontBuf->FB_minTSB ), fontMatrix->FM_22 ) );
                fontBuf->FB_pixHeight += fontBuf->FB_minTSB;

                if( fontMatrix->FM_flags & TF_ROTATED )
                {
                        /* adjust scriptX and heightX */
                        transMatrix->TM_heightX = INTEGER_OF_WWFIXEDASDWORD( GrMulWWFixed( 
                                                        WORD_TO_WWFIXEDASDWORD( fontBuf->FB_baselinePos.WBF_int ), transMatrix->TM_matrix.yx ) );
                        transMatrix->TM_scriptX = INTEGER_OF_WWFIXEDASDWORD( GrMulWWFixed( 
                                                        WORD_TO_WWFIXEDASDWORD( savedScriptY ), transMatrix->TM_matrix.yx ) );
                }
        }
}


/********************************************************************
 *                      IsRegionNeeded
 ********************************************************************
 * SYNOPSIS:       Determines if a given region is needed based on 
 *                 transformation parameters and font metrics.
 * 
 * PARAMETERS:     TransformMatrix* transMatrix
 *                    Pointer to the transformation matrix that holds
 *                    scaling and transformation values for the font.
 *                 FontBuf* fontBuf
 *                    Pointer to `FontBuf` containing various font metrics.
 * 
 * RETURNS:        Boolean
 *                    TRUE if the resulting transformation exceeds the
 *                    maximum bitmap size (`MAX_BITMAP_SIZE`), indicating 
 *                    that the region is needed. FALSE otherwise.
 * 
 * STRATEGY:       - The function calculates transformed values of the
 *                   font height based on the transformation matrix.
 *                 - It checks the resulting parameters to determine if 
 *                   their absolute values exceed `MAX_BITMAP_SIZE`.
 *                 - If any transformed value is greater than the limit, 
 *                   the function returns TRUE.
 *                 - The height and script offsets are also checked to see 
 *                   if they exceed `MAX_BITMAP_SIZE`.
 *                 - If none of these conditions are met, the function 
 *                   returns FALSE.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      22.07.23  JK        Initial Revision
 *******************************************************************/

static Boolean IsRegionNeeded( TransformMatrix* transMatrix, FontBuf* fontBuf )
{
        sword param1;
        sword param2;


        param1 = IntegerOf( GrMulWWFixed( transMatrix->TM_matrix.xx, WORD_TO_WWFIXEDASDWORD( fontBuf->FB_pixHeight ) ) );
        param2 = IntegerOf( GrMulWWFixed( transMatrix->TM_matrix.yx, WORD_TO_WWFIXEDASDWORD( fontBuf->FB_pixHeight ) ) );
        if( ( ABS( param1 ) + ABS( param2 ) ) > MAX_BITMAP_SIZE )
                return TRUE;

        param1 = IntegerOf( GrMulWWFixed( transMatrix->TM_matrix.xy, WORD_TO_WWFIXEDASDWORD( fontBuf->FB_pixHeight ) ) );
        param2 = IntegerOf( GrMulWWFixed( transMatrix->TM_matrix.yy, WORD_TO_WWFIXEDASDWORD( fontBuf->FB_pixHeight ) ) );
        if( ( ABS( param1 ) + ABS( param2 ) ) > MAX_BITMAP_SIZE )
                return TRUE;

        if( transMatrix->TM_heightX + transMatrix->TM_scriptX > MAX_BITMAP_SIZE )
                return TRUE;

        if( transMatrix->TM_heightY + transMatrix->TM_scriptY > MAX_BITMAP_SIZE )
                return TRUE;

        return FALSE;
}
