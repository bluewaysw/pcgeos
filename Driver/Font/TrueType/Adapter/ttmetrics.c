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
                                 TransformMatrix*  transMatrix );

static void CalcScaleForWidths( TRUETYPE_VARS, 
                                WWFixedAsDWord     pointSize, 
                                TextStyle          stylesToImplement );

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
 *                result                Pointer in wich the result will 
 *                                      stored.
 *                varBlock              Memory handle to var block.
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
 *      23/12/22  JK        Initial Revision
 *******************************************************************/

void _pascal TrueType_Char_Metrics( 
                                   word                 character, 
                                   GCM_info             info, 
                                   const FontInfo*      fontInfo,
	                           const OutlineEntry*  outlineEntry, 
                                   TextStyle            stylesToImplement,
                                   WWFixedAsDWord       pointSize,
                                   WWFixedAsDWord*      result,
                                   MemHandle            varBlock ) 
{
        TrueTypeOutlineEntry*  trueTypeOutline;
        TransformMatrix        transMatrix;
        word                   charIndex;
        TrueTypeVars*          trueTypeVars;


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

        CalcScaleForWidths( trueTypeVars, pointSize, stylesToImplement );
        CalcTransformMatrix( stylesToImplement, &transMatrix );

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
                        *result = GrMulWWFixed( MakeWWFixed( GLYPH_BBOX.xMin ), SCALE_WIDTH );
                        break;
                case GCMI_MIN_Y:
                case GCMI_MIN_Y_ROUNDED:
                        *result = GrMulWWFixed( MakeWWFixed( GLYPH_BBOX.yMin ), SCALE_HEIGHT );
                        break;
                case GCMI_MAX_X:
                case GCMI_MAX_X_ROUNDED:
                        *result = GrMulWWFixed( MakeWWFixed( GLYPH_BBOX.xMax ), SCALE_WIDTH );
                        break;
                case GCMI_MAX_Y:
                case GCMI_MAX_Y_ROUNDED:
                        *result = GrMulWWFixed( MakeWWFixed( GLYPH_BBOX.yMax ), SCALE_HEIGHT );
                        break;
        }

        TT_Done_Glyph( GLYPH );
        TrueType_Unlock_Face( trueTypeVars );

Fail:
        MemUnlock( varBlock );
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

static void CalcScaleForWidths( TRUETYPE_VARS, 
                                WWFixedAsDWord  pointSize, 
                                TextStyle       stylesToImplement )
{
        SCALE_HEIGHT = GrUDivWWFixed( pointSize, MakeWWFixed( FACE_PROPERTIES.header->Units_Per_EM ) );
        SCALE_WIDTH  = SCALE_HEIGHT;

        if( stylesToImplement & ( TS_BOLD ) )
                SCALE_WIDTH = GrMulWWFixed( SCALE_WIDTH, WWFIXED_1_POINR_1 );

        if( stylesToImplement & ( TS_SUBSCRIPT | TS_SUPERSCRIPT ) )     
                SCALE_WIDTH = GrMulWWFixed( SCALE_WIDTH, WWFIXED_0_POINT_5 );
}


/********************************************************************
 *                      CalcTransformMatrix
 ********************************************************************
 * SYNOPSIS:	  Calculates the transformation matrix for missing
 *                style attributes and weights.
 * 
 * PARAMETERS:    styleToImplement      Styles that must be added.
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
 *******************************************************************/

static void CalcTransformMatrix( TextStyle         stylesToImplement,
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
