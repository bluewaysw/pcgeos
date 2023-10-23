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


static void CalcTransformMatrix( TransMatrix*    transMatrix, 
                                 WWFixedAsDWord  pointSize, 
                                 TextStyle       stylesToImplement );

static void ScaleOutline( TRUETYPE_VARS, WWFixedAsDWord scale );

static void ConvertOutline( GStateHandle gstate, TT_Outline* outline );


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
                        const OutlineEntry*  firstEntry,
                        TextStyle            stylesToImplement,
                        MemHandle            varBlock )
{
        TrueTypeVars*          trueTypeVars;
        TrueTypeOutlineEntry*  trueTypeOutline;
        TransMatrix            transMatrix;
        TT_UShort              charIndex;
        WWFixedAsDWord         pointSize;
        WWFixedAsDWord         scalePointSize;
        XYValueAsDWord         cursorPos;


EC(     ECCheckGStateHandle( gstate ) );
EC(     ECCheckBounds( (void*)fontInfo ) );
EC(     ECCheckBounds( (void*)outlineEntry ) );
EC(     ECCheckBounds( (void*)firstEntry ) );
EC(     ECCheckMemHandle( varBlock ) );

        /* get trueTypeVar block */
        trueTypeVars = MemLock( varBlock );
EC(     ECCheckBounds( (void*)trueTypeVars ) );

        trueTypeOutline = LMemDerefHandles( MemPtrToHandle( (void*)fontInfo ), outlineEntry->OE_handle );

        /* open face, create instance and glyph */
        if( TrueType_Lock_Face(trueTypeVars, trueTypeOutline) )
                goto Fin;

        TT_New_Glyph( FACE, &GLYPH );

        /* get TT char index */
        charIndex = TT_Char_Index( CHAR_MAP, GeosCharToUnicode( character ) );

        /* write prologue */
        if( pathFlags & FGPF_SAVE_STATE )
                GrSaveState( gstate );

        /* load glyph and scale its outline to 1000 units per em */
        TT_Load_Glyph( INSTANCE, GLYPH, charIndex, 0 );
        TT_Get_Glyph_Outline( GLYPH, &OUTLINE );
        ScaleOutline( trueTypeVars, GrUDivWWFixed( 
                ((dword)STANDARD_GRIDSIZE) << 16, ((dword)UNITS_PER_EM) << 16 ) );

        /* write comment with glyph parameters */
        WriteComment( trueTypeVars, gstate );

        /* Here's the sequence of operation we should need to perform      */
	/* on an arbitrary point in the font outline                       */
	/*	1) Transform by font TransMatrix                           */
	/*	2) Flip on X-axis (scale by -1 in Y)                       */
	/*	3) Translate by font height                                */
	/*	4) Translate by current position                           */
	/*	5) Transform by current matrix                             */
	/*                                                                 */
	/* Remember that since the order of matrix multiplication is       */
	/* extremely important, we must perform these transformations      */
	/* in reverse order. Step 5 is, of course, already in the GState.  */

        /* translate by current cursor position */
        cursorPos = GrGetCurPos( gstate );
        GrApplyTranslationDWord( gstate, DWORD_X( cursorPos ), DWORD_Y( cursorPos ) );

        /* we only perform steps 2 & 3 if the POSTSCRIPT flag wasn't passed */
        if( !(pathFlags & FGPF_POSTSCRIPT) )
        {
                GrGetFont( gstate, &pointSize );
                scalePointSize = GrUDivWWFixed( pointSize, MakeWWFixed( STANDARD_GRIDSIZE ) );

                //TODO:
                //ascent und accent laden
                //translation = ( accent + ascent ) * scalePointsize
                //AppyTranslate( 0, translation )

                //Test
                GrApplyTranslationDWord( gstate, 0, 199 );

                /* flip on x-axis */ 
                GrApplyScale( gstate, 1L << 16, -1L << 16 );

        }

        /* calc scaling factor and calculate transformation matrix */
        GrGetTransform( gstate, &transMatrix );
        
        //TODO: auslagern und korrigieren
        transMatrix.TM_e11.WWF_frac = 16384;
        transMatrix.TM_e11.WWF_int  = 0;
        transMatrix.TM_e22.WWF_frac = 16384;
        transMatrix.TM_e22.WWF_int  = 0;
        transMatrix.TM_e31.DWF_frac = 0;
        transMatrix.TM_e31.DWF_int  = 0;
        transMatrix.TM_e32.DWF_frac = 0;
        transMatrix.TM_e32.DWF_int  = 0;
        GrApplyTransform( gstate, &transMatrix );
        
        /* convert outline into GrDraw...() calls */
        ConvertOutline( gstate, &OUTLINE);

        /* write epilogue */
        if( pathFlags & FGPF_SAVE_STATE )
                GrRestoreState( gstate );

Fail:
        TT_Done_Glyph( GLYPH );

Fin:
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
 *                      ConvertOutline
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
 *      22/10/23  JK        Initial Revision
 *******************************************************************/

static void ConvertOutline( GStateHandle gstate, TT_Outline* outline )
{
        if( outline->contours <= 0 || outline->points == 0 )
                return;

        //TODO: iteriere über Konturen
        //              wandle Segmente in Gr... Kommandos






        // Test mit Bindestrich
        GrMoveTo( gstate, 198, 303 );
        GrDrawVLineTo( gstate, 269 );
        GrDrawHLineTo( gstate, 401 );
        GrDrawVLineTo( gstate, 303 );
        GrDrawHLineTo( gstate, 198 );

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

        TT_Transform_Outline( &OUTLINE, &matrix );
}


static void CalcTransformMatrix( TransMatrix*    transMatrix, 
                                 WWFixedAsDWord  pointSize, 
                                 TextStyle       stylesToImplement )
{
        WWFixedAsDWord scale = GrUDivWWFixed( pointSize, MakeWWFixed( STANDARD_GRIDSIZE ) );


        transMatrix->TM_e11.WWF_frac = scale & 0x0000ffff;
        transMatrix->TM_e11.WWF_int  = scale >> 16;
        transMatrix->TM_e22.WWF_frac = scale & 0x0000ffff;
        transMatrix->TM_e22.WWF_int  = scale >> 16;



        //TODO Styles einbauen
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
        params[0] = 600; //GLYPH_METRICS.advance;// GLYPH_BBOX.xMax - GLYPH_BBOX.xMin; //width
        params[1] = 0; //GLYPH_BBOX.yMax - GLYPH_BBOX.yMin; //height
        params[2] = 198; //GLYPH_BBOX.xMin;
        params[3] = 269; //GLYPH_BBOX.yMin;
        params[4] = 401; //GLYPH_BBOX.xMax;
        params[5] = 303; //GLYPH_BBOX.yMax;


        GrComment( gstate, &params, NUM_PARAMS );
}
