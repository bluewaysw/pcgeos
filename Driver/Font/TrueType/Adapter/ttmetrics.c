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


static void CalcTransformMatrix( TextStyle         stylesToImplement,
                                 Byte              width,
                                 Byte              weight,
                                 TransformMatrix*  transMatrix );

static void CalcScaleForWidths( TRUETYPE_VARS, 
                                WWFixedAsDWord     pointSize, 
                                TextStyle          stylesToImplement,
                                Byte               width,
                                Byte               weight );

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
        TransformMatrix        transMatrix;
        word                   charIndex;
        TrueTypeVars*          trueTypeVars;
        WWFixedAsDWord         result;


EC(     ECCheckBounds( (void*)fontInfo ) );
EC(     ECCheckBounds( (void*)outlineEntry ) );
EC(     ECCheckMemHandle( varBlock ) );
EC(     ECCheckStack() );


        /* get trueTypeVar block */
        trueTypeVars = MemLock( varBlock );
EC(     ECCheckBounds( (void*)trueTypeVars ) );

        trueTypeOutline = LMemDerefHandles( MemPtrToHandle( (void*)fontInfo ), outlineEntry->OE_handle );

        if( TrueType_Lock_Face(trueTypeVars, trueTypeOutline) )
                goto Fail;

        CalcScaleForWidths( trueTypeVars, pointSize, stylesToImplement, width, weight );
        CalcTransformMatrix( stylesToImplement, width, weight, &transMatrix );

        // get TT char index
        charIndex = TT_Char_Index( CHAR_MAP, GeosCharToUnicode( character ) );

        // load glyph
        TT_New_Glyph( FACE, &GLYPH );
        TT_Load_Glyph( INSTANCE, GLYPH, charIndex, 0 );

        // transform glyphs outline
        TT_Get_Glyph_Outline( GLYPH, &OUTLINE );
        TT_Transform_Outline( &OUTLINE, &transMatrix.TM_matrix );
        TT_Translate_Outline( &OUTLINE, 0, WWFIXEDASDWORD_TO_FIXED26DOT6( transMatrix.TM_scriptY ) );

        // get metrics
        TT_Get_Glyph_Metrics( GLYPH, &GLYPH_METRICS );

        switch( info )
        {
                case GCMI_MIN_X:
                case GCMI_MIN_X_ROUNDED:
                        result = GrMulWWFixed( WORD_TO_WWFIXEDASDWORD( GLYPH_BBOX.xMin ), SCALE_WIDTH );
                        break;
                case GCMI_MIN_Y:
                case GCMI_MIN_Y_ROUNDED:
                        result = GrMulWWFixed( WORD_TO_WWFIXEDASDWORD( GLYPH_BBOX.yMin ), SCALE_HEIGHT );
                        break;
                case GCMI_MAX_X:
                case GCMI_MAX_X_ROUNDED:
                        result = GrMulWWFixed( WORD_TO_WWFIXEDASDWORD( GLYPH_BBOX.xMax ), SCALE_WIDTH );
                        break;
                case GCMI_MAX_Y:
                case GCMI_MAX_Y_ROUNDED:
                        result = GrMulWWFixed( WORD_TO_WWFIXEDASDWORD( GLYPH_BBOX.yMax ), SCALE_HEIGHT );
                        break;
        }

        TT_Done_Glyph( GLYPH );
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
 *      10702724  JK        width and weight implemented
 *******************************************************************/

static void CalcScaleForWidths( TRUETYPE_VARS, 
                                WWFixedAsDWord  pointSize, 
                                TextStyle       stylesToImplement,
                                Byte            width,
                                Byte            weight )
{
        SCALE_HEIGHT = SCALE_WIDTH = GrUDivWWFixed( pointSize, MakeWWFixed( FACE_PROPERTIES.header->Units_Per_EM ) );

        if( stylesToImplement & ( TS_BOLD ) )
                SCALE_WIDTH = GrMulWWFixed( SCALE_WIDTH, WWFIXED_1_POINR_1 );

        if( stylesToImplement & ( TS_SUBSCRIPT | TS_SUPERSCRIPT ) )     
                SCALE_WIDTH = GrMulWWFixed( SCALE_WIDTH, WWFIXED_0_POINT_5 );

        /* implement width and weight */
        if( width != FWI_MEDIUM )
                SCALE_WIDTH = MUL_100_WWFIXED( SCALE_WIDTH, width );

        if( weight != FW_NORMAL )
                SCALE_WIDTH = MUL_100_WWFIXED( SCALE_WIDTH, weight );
}


/********************************************************************
 *                      CalcTransformMatrix
 ********************************************************************
 * SYNOPSIS:	  Calculates the transformation matrix for missing
 *                style attributes and weights.
 * 
 * PARAMETERS:    styleToImplement      Styles that must be added.
 *                width                 Desired glyph width.
 *                weight                Desired glyph weight.
 *                *transMatrix          Pointer to TransformMatrix.
 *                      
 * RETURNS:       void
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      20/12/22  JK        Initial Revision
 *      10/02/24  JK        width and weight implemented
 *******************************************************************/

static void CalcTransformMatrix( TextStyle         stylesToImplement,
                                 Byte              width,
                                 Byte              weight,
                                 TransformMatrix*  transMatrix )
{
        /* make unity matrix       */
        transMatrix->TM_matrix.xx = 1L << 16;
        transMatrix->TM_matrix.xy = 0;
        transMatrix->TM_matrix.yx = 0;
        transMatrix->TM_matrix.yy = 1L << 16;
        transMatrix->TM_scriptY   = 0;

        /* fake bold style         */
        if( stylesToImplement & TS_BOLD )
                transMatrix->TM_matrix.xx = BOLD_FACTOR;

        /* fake italic style       */
        if( stylesToImplement & TS_ITALIC )
                transMatrix->TM_matrix.yx = ITALIC_FACTOR;

        /* width and weight */
        if( width != FWI_MEDIUM )
                transMatrix->TM_matrix.xx = MUL_100_WWFIXED( transMatrix->TM_matrix.xx, width );

        if( weight != FW_NORMAL )
                transMatrix->TM_matrix.xx = MUL_100_WWFIXED( transMatrix->TM_matrix.xx, weight );

        /* fake script style       */
        if( stylesToImplement & ( TS_SUBSCRIPT | TS_SUBSCRIPT ) )
        {      
                transMatrix->TM_matrix.xx = GrMulWWFixed( transMatrix->TM_matrix.xx, SCRIPT_FACTOR );
                transMatrix->TM_matrix.yy = GrMulWWFixed( transMatrix->TM_matrix.yy, SCRIPT_FACTOR );

                if( stylesToImplement & TS_SUBSCRIPT )
                        transMatrix->TM_scriptY = -SCRIPT_SHIFT_FACTOR;
                else
                        transMatrix->TM_scriptY = SCRIPT_SHIFT_FACTOR;
        }
}
