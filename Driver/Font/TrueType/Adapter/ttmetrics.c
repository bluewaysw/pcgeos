/***********************************************************************
 *
 *                      Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttadapter.c
 *
 * AUTHOR:	  Jirka Kunze: December 23 2022
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	12/23/22  JK	    Initial version
 *
 * DESCRIPTION:
 *	Definition of driver function DR_FONT_CHAR_METRICS.
 ***********************************************************************/

#include "ttadapter.h"
#include "ttmetrics.h"
#include "ttadapter.h"
#include "freetype.h"
#include "ttcharmapper.h"
#include <ec.h>


static void CalcScaleForWidths( TRUETYPE_VARS,
                                WWFixedAsDWord pointSize,
                                TextStyle      stylesToImplement,
                                Byte           width,
                                Byte           weight );

static WWFixedAsDWord CalcScriptOffset( TRUETYPE_VARS,
                                        WWFixedAsDWord pointSize,
                                        TextStyle      stylesToImplement );

/********************************************************************
 *                      TrueType_Char_Metrics
 ********************************************************************
 * SYNOPSIS:	  Return character metrics information in document coords.
 * 
 * PARAMETERS:    character             Character to get metrics of.
 *                info                  Info to return (GCM_info).
 *                *fontInfo             Ptr. to font info structure.
 *                *outlineEntry         Ptr. to outline entry containing 
 *                                      TrueTypeOutlineEntry.
 *                stylesToImplement     Desired text style.
 *                pointSize             Desired point size.
 *                width                 Desired glyph width.
 *                weight                Desired glyph weight.
 *                varBlock              Memory handle to var block.
 * 
 * RETURNS:       WWFixedAsDWord
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      23/12/22  JK        Initial Revision
 *      10/02/24  JK        width and weight implemented
 *******************************************************************/

WWFixedAsDWord _pascal TrueType_Char_Metrics(
                                   word                 character,
                                   GCM_info             info,
                                   const FontInfo*      fontInfo,
                                   const OutlineEntry*  outlineEntry,
                                   TextStyle            stylesToImplement,
                                   WWFixedAsDWord       pointSize,
                                   Byte                 width,
                                   Byte                 weight,
                                   MemHandle            varBlock )
{
        TrueTypeOutlineEntry*  trueTypeOutline;
        TT_Glyph_Metrics       glyphMetrics;
        word                   charIndex;
        TrueTypeVars*          trueTypeVars;
        WWFixedAsDWord         result = 0;
        WWFixedAsDWord         scriptOffset;
        WWFixedAsDWord         italicScale = 0;


EC(     ECCheckBounds( (void*)fontInfo ) );
EC(     ECCheckBounds( (void*)outlineEntry ) );
EC(     ECCheckMemHandle( varBlock ) );
EC(     ECCheckStack() );


        /* get trueTypeVar block */
        trueTypeVars = MemLock( varBlock );
EC(     ECCheckBounds( (void*)trueTypeVars ) );

        trueTypeOutline = LMemDerefHandles( MemPtrToHandle( (void*)fontInfo ), outlineEntry->OE_handle );

        if( TrueType_Lock_Face( trueTypeVars, trueTypeOutline ) )
                goto Fail;

        CalcScaleForWidths( trueTypeVars, pointSize, stylesToImplement, width, weight );

        scriptOffset = CalcScriptOffset( trueTypeVars, pointSize, stylesToImplement );

        /* italic shears X by Y */
        if( stylesToImplement & TS_ITALIC )
                italicScale = GrMulWWFixed( SCALE_HEIGHT, ITALIC_FACTOR );

        /* get TT char index */
        charIndex = TT_Char_Index( CHAR_MAP, GeosCharToUnicode( character ) );

        /* load unscaled glyph */
        if( TT_Load_Glyph( INSTANCE, GLYPH, charIndex, 0 ) )
                goto UnlockFace;

        TT_Get_Glyph_Metrics( GLYPH, &glyphMetrics );

        switch( info )
        {
                case GCMI_MIN_X:
                case GCMI_MIN_X_ROUNDED:
                        result = GrMulWWFixed( WORD_TO_WWFIXEDASDWORD( glyphMetrics.bbox.xMin ), SCALE_WIDTH );

                        if( italicScale )
                                result += GrMulWWFixed( WORD_TO_WWFIXEDASDWORD( glyphMetrics.bbox.yMin ), italicScale );
                        break;

                case GCMI_MIN_Y:
                case GCMI_MIN_Y_ROUNDED:
                        result = GrMulWWFixed( WORD_TO_WWFIXEDASDWORD( glyphMetrics.bbox.yMin ), SCALE_HEIGHT );
                        result += scriptOffset;
                        break;

                case GCMI_MAX_X:
                case GCMI_MAX_X_ROUNDED:
                        result = GrMulWWFixed( WORD_TO_WWFIXEDASDWORD( glyphMetrics.bbox.xMax ), SCALE_WIDTH );

                        if( italicScale )
                                result += GrMulWWFixed( WORD_TO_WWFIXEDASDWORD( glyphMetrics.bbox.yMax ), italicScale );
                        break;

                case GCMI_MAX_Y:
                case GCMI_MAX_Y_ROUNDED:
                        result = GrMulWWFixed( WORD_TO_WWFIXEDASDWORD( glyphMetrics.bbox.yMax ), SCALE_HEIGHT );
                        result += scriptOffset;
                        break;
        }

UnlockFace:
        TrueType_Unlock_Face( trueTypeVars );

Fail:
        MemUnlock( varBlock );

        return result;
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
 *                width                 Desired glyph width.
 *                weight                Desired glyph weight.
 * 
 * RETURNS:       void
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20/07/23  JK        Initial Revision
 *      10/02/24  JK        width and weight implemented
 *******************************************************************/

static void CalcScaleForWidths( TRUETYPE_VARS,
                                WWFixedAsDWord pointSize,
                                TextStyle      stylesToImplement,
                                Byte           width,
                                Byte           weight )
{
        SCALE_HEIGHT = GrUDivWWFixed( pointSize, MakeWWFixed( FACE_PROPERTIES.header->Units_Per_EM ) );

        SCALE_WIDTH = SCALE_HEIGHT;

        /* fake bold style */
        if( stylesToImplement & TS_BOLD )
                SCALE_WIDTH = GrMulWWFixed( SCALE_WIDTH, WWFIXED_1_POINR_1 );

        if( stylesToImplement & ( TS_SUBSCRIPT | TS_SUPERSCRIPT ) )
        {
                SCALE_WIDTH  = GrMulWWFixed( SCALE_WIDTH, WWFIXED_0_POINT_5 );
                SCALE_HEIGHT = GrMulWWFixed( SCALE_HEIGHT, WWFIXED_0_POINT_5 );
        }

        /* implement width and weight */
        if( width != FWI_MEDIUM )
                SCALE_WIDTH = MUL_100_WWFIXED( SCALE_WIDTH, width );

        if( weight != FW_NORMAL )
                SCALE_WIDTH = MUL_100_WWFIXED( SCALE_WIDTH, weight );
}


static WWFixedAsDWord CalcScriptOffset( TRUETYPE_VARS,
                                        WWFixedAsDWord pointSize,
                                        TextStyle      stylesToImplement )
{
        WWFixedAsDWord scaleHeight;
        WWFixedAsDWord height;
        WWFixedAsDWord heightAdjust;
        WWFixedAsDWord scriptHeight;
        WWFixedAsDWord baseline;
        WWFixedAsDWord baseAdjust;


        if( !( stylesToImplement & ( TS_SUBSCRIPT | TS_SUPERSCRIPT ) ) )
                return 0;

        scaleHeight  = GrUDivWWFixed( pointSize, MakeWWFixed( FACE_PROPERTIES.header->Units_Per_EM ) );
        height       = WORD_TO_WWFIXEDASDWORD( INTEGER_OF_WWFIXEDASDWORD( SCALE_WORD(
                                FACE_PROPERTIES.os2->usWinAscent + FACE_PROPERTIES.os2->usWinDescent, scaleHeight ) ) );
        heightAdjust = SCALE_WORD( FACE_PROPERTIES.os2->sTypoAscender - FACE_PROPERTIES.header->yMax, scaleHeight );
        scriptHeight = height + ( heightAdjust & 0xffffff00L );

        if( stylesToImplement & TS_SUBSCRIPT )
                return -GrMulWWFixed( scriptHeight, SUBSCRIPT_OFFSET );

        baseline   = WORD_TO_WWFIXEDASDWORD( INTEGER_OF_WWFIXEDASDWORD( SCALE_WORD(
                                FACE_PROPERTIES.os2->usWinAscent, scaleHeight ) + 0x8000 ) );
        baseAdjust = WORD_TO_WWFIXEDASDWORD( INTEGER_OF_WWFIXEDASDWORD( heightAdjust + 0x8000 ) );

        return baseline + baseAdjust - GrMulWWFixed( scriptHeight, SUPERSCRIPT_OFFSET );
}
