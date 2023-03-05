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

/********************************************************************
 *                      TrueType_Char_Metrics
 ********************************************************************
 * SYNOPSIS:	  Return character metrics information in document coords.
 * 
 * PARAMETERS:    character             Character to get metrics of.
 *                info                  Info to return (GCM_info).
 *                *fontInfo              
 *                *outlineData
 *                stylesToImplement
 *                result                Pointer in wich the result will 
 *                                      stored.
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      23/12/22  JK        Initial Revision
 * 
 *******************************************************************/
TT_Error _pascal TrueType_Char_Metrics( 
                                   word                 character, 
                                   GCM_info             info, 
                                   const FontInfo*      fontInfo,
	                           const OutlineEntry*  outlineEntry, 
                                   TextStyle            stylesToImplement,
                                   WWFixedAsDWord       pointSize,
                                   dword*               result ) 
{
        FileHandle             truetypeFile;
        TrueTypeOutlineEntry*  trueTypeOutline;
        TransformMatrix        transMatrix;
        TT_Face                face;
        word                   charIndex;
        TT_Outline             outline;
        TT_Instance            instance;
        TT_Instance_Metrics    instanceMetrics;
        TT_CharMap             charMap;
        TT_Glyph               glyph;
        TT_Glyph_Metrics       glyphMetrics;
        TT_Error               error;


        ECCheckBounds( (void*)fontInfo );
        ECCheckBounds( (void*)outlineEntry );


        // get filename an load ttf file 
        FilePushDir();
        FileSetCurrentPath( SP_FONT, TTF_DIRECTORY );

        trueTypeOutline = LMemDerefHandles( MemPtrToHandle( (void*)fontInfo ), outlineEntry->OE_handle );
        truetypeFile = FileOpen( trueTypeOutline->TTOE_fontFileName, FILE_ACCESS_R | FILE_DENY_W );
        
        ECCheckFileHandle( truetypeFile );

        CalcTransformMatrix( stylesToImplement, &transMatrix );

        error = TT_Open_Face( truetypeFile, &face );
        if( error )
                goto Fail;

        // get TT char index
        getCharMap( face, &charMap );

        charIndex = TT_Char_Index( charMap, GeosCharToUnicode( character ) );

        // load glyph
        TT_New_Glyph( face, &glyph );
        TT_New_Instance( face, &instance );

        // transform glyphs outline
        TT_Get_Glyph_Outline( glyph, &outline );
        TT_Transform_Outline( &outline, &transMatrix.TM_matrix );
        TT_Translate_Outline( &outline, 0, WWFIXEDASDWORD_TO_FIXED26DOT6( transMatrix.TM_shiftY ) );

        // scale glyph
        TT_Set_Instance_CharSize( instance, ( pointSize >> 10 ) );
        TT_Get_Instance_Metrics( instance, &instanceMetrics );

        // get metrics
        TT_Get_Glyph_Metrics( glyph, &glyphMetrics );

        switch( info )
        {
                case GCMI_MIN_X:
                case GCMI_MIN_X_ROUNDED:
                        *result = SCALE_WORD( glyphMetrics.bbox.xMin, instanceMetrics.x_scale );
                        break;
                case GCMI_MIN_Y:
                case GCMI_MIN_Y_ROUNDED:
                        *result = SCALE_WORD( glyphMetrics.bbox.yMin, instanceMetrics.y_scale );
                        break;
                case GCMI_MAX_X:
                case GCMI_MAX_X_ROUNDED:
                        *result = SCALE_WORD( glyphMetrics.bbox.xMax, instanceMetrics.x_scale );
                        break;
                case GCMI_MAX_Y:
                case GCMI_MAX_Y_ROUNDED:
                        *result = SCALE_WORD( glyphMetrics.bbox.yMax, instanceMetrics.y_scale );
                        break;
        }

        TT_Done_Instance( instance );
        TT_Done_Glyph( glyph );

Fail:
        TT_Close_Face( face );
        FileClose( truetypeFile, FALSE );
        FilePopDir();
        return error;
}


static void CalcTransformMatrix( TextStyle         stylesToImplement,
                                 TransformMatrix*  transMatrix )
{
        /* make unity matrix       */
        transMatrix->TM_matrix.xx = 1 << 16;
        transMatrix->TM_matrix.xy = 0;
        transMatrix->TM_matrix.yx = 0;
        transMatrix->TM_matrix.yy = 1 << 16;
        transMatrix->TM_shiftY    = 0;

        /* fake bold style         */
        if( stylesToImplement & TS_BOLD )
                transMatrix->TM_matrix.xx = BOLD_FACTOR;

        /* fake italic style       */
        if( stylesToImplement & TS_ITALIC )
                transMatrix->TM_matrix.yx = ITALIC_FACTOR;

        /* fake script style       */
        if( stylesToImplement & TS_SUBSCRIPT || stylesToImplement & TS_SUBSCRIPT )
        {      
                transMatrix->TM_matrix.xx = GrMulWWFixed( transMatrix->TM_matrix.xx, SCRIPT_FACTOR );
                transMatrix->TM_matrix.yy = GrMulWWFixed( transMatrix->TM_matrix.yy, SCRIPT_FACTOR );

                if( stylesToImplement & TS_SUBSCRIPT )
                        transMatrix->TM_shiftY = -SCRIPT_SHIFT_FACTOR;
                else
                        transMatrix->TM_shiftY = SCRIPT_SHIFT_FACTOR;
        }
}
