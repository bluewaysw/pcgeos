/***********************************************************************
 *
 *                      Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttpath.c
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
#include "ttpath.h"
#include "ttcharmapper.h"
#include <ec.h>


static void CalcTransformMatrix( TransformMatrix* transMatrix );

static void ScaleOutline( TRUETYPE_VARS, WWFixedAsDWord scale );


/********************************************************************
 *                      TrueType_Gen_Path
 ********************************************************************
 * SYNOPSIS:	  Draw outline of the given charcode to gstate.
 * 
 * PARAMETERS:    gstate                GStateHande in which the outline 
 *                                      of the character is written.
 *                pathFlags             FGPF_POSTSCRIPT - transform for 
 *                                           use as Postscript Type 1 or Type 3 font.
 *			                FGPF_SAVE_STATE - do save/restore for GState
 *                character             Character to build (GEOS Char).
 *                pointSize             Desired point size.
 *                *fontInfo             Pointer to FontInfo structure.
 *                *outlineEntry         Ptr. to outline entry containing 
 *                                      TrueTypeOutlineEntry.
 *                varBlock              Memory handle to var block.
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

void _pascal TrueType_Gen_Path(          
                        GStateHandle         gstate,
                        FontGenPathFlags     pathFlags,
                        word                 character,
                        const FontInfo*      fontInfo, 
                        const OutlineEntry*  outlineEntry,
                        MemHandle            varBlock )
{
        TrueTypeVars*          trueTypeVars;
        TrueTypeOutlineEntry*  trueTypeOutline;
        TransformMatrix        transMatrix;
        TransMatrix            mat;
        TT_UShort              charIndex;
        WWFixedAsDWord         pointSize;
        WWFixedAsDWord         scalePointSize;
        XYValueAsDWord         cursorPos;


EC(     ECCheckGStateHandle( gstate ) );
EC(     ECCheckBounds( (void*)fontInfo ) );
EC(     ECCheckBounds( (void*)outlineEntry ) );
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

        /* calc scaling factor */
        GrGetFont( gstate, &pointSize );
        scalePointSize = GrUDivWWFixed( pointSize, STANDARD_GRIDSIZE );

        /* write prologue */
        if( pathFlags & FGPF_SAVE_STATE )
                GrSaveState( gstate );

        /* load glyph and scale its outline to 1000 units per em */
        TT_Load_Glyph( INSTANCE, GLYPH, charIndex, 0 );
        TT_Get_Glyph_Outline( GLYPH, &OUTLINE );
        ScaleOutline( trueTypeVars, GrUDivWWFixed( STANDARD_GRIDSIZE, UNITS_PER_EM ) );

        /* write comment with glyph parameters */
        WriteComment( trueTypeVars, gstate );

        /* translate to current cursor position */
        cursorPos = GrGetCurPos( gstate );
        GrApplyTranslationDWord( gstate, DWORD_X( cursorPos ), DWORD_Y( cursorPos ) );

        if( pathFlags & FGPF_POSTSCRIPT )
        {
                //TODO:
                //pointSize      = GrGetFont()
                //scalePointsize = pointSize / UnitsPerEM
      
                //accent         = FontHeader.FH_accent * scaleGrid
                //ascent         = FontHeader.FH_ascent * scaleGrid
      
                //translation    = (accent + ascent)
                //Translate( gstate, 0, translation )
                //Scaliere( gstate, 1, -1 ); 
        }

        /* calc tranfomation matrix and apply it */
        CalcTransformMatrix( &transMatrix );
        TT_Transform_Outline( &OUTLINE, &transMatrix.TM_matrix );
        
        //TODO:
        //setze Pointsize
        //scaliere Glyph
        //iteriere über Outline
        //      iteriere über Konturen
        //              wandle Segmente in Gr... Kommandos

        /* write epilogue */
        if( pathFlags & FGPF_SAVE_STATE )
                GrRestoreState( gstate );

        TT_Done_Glyph( GLYPH );

Fail:
        MemUnlock( varBlock );
}


/********************************************************************
 *                      TrueType_Gen_In_Region
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

void _pascal TrueType_Gen_In_Region( 
                        GStateHandle         gstate,
                        Handle               regionPath,
                        word                 character,
                        WWFixedAsDWord       pointSize,
			const FontInfo*      fontInfo, 
                        const OutlineEntry*  outlineEntry,
                        MemHandle            varBlock )
{

}

/********************************************************************
 *                      ScaleOutline
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
 *      14/10/23  JK        Initial Revision
 *******************************************************************/

static void ScaleOutline( TRUETYPE_VARS, WWFixedAsDWord scale )
{
        TT_Matrix matrix = { 0, 0, 0, 0};
        
        matrix.xx = scale;
        matrix.yy = scale;

        TT_Transform_Outline( 0, &matrix );
}


static void CalcTransformMatrix( TransformMatrix* transMatrix )
{
        transMatrix->TM_matrix.xx = 1L << 16;
        transMatrix->TM_matrix.xy = 0;
        transMatrix->TM_matrix.yx = 0;
        transMatrix->TM_matrix.yy = 1L << 16;

        //TODO
}


/********************************************************************
 *                      WriteComment
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
 *      14/10/23  JK        Initial Revision
 *******************************************************************/

#define NUM_PARAMS              6
static void WriteComment( TRUETYPE_VARS, GStateHandle gstate )
{
        word params[NUM_PARAMS];


        TT_Get_Glyph_Metrics( GLYPH, &GLYPH_METRICS );
        params[0] = GLYPH_BBOX.xMax - GLYPH_BBOX.xMin; //width
        params[1] = 0; //GLYPH_BBOX.yMax - GLYPH_BBOX.yMin; //height
        params[2] = GLYPH_BBOX.xMin;
        params[3] = GLYPH_BBOX.yMin;
        params[4] = GLYPH_BBOX.xMax;
        params[5] = GLYPH_BBOX.yMax;
        GrComment( gstate, &params, NUM_PARAMS );
}
