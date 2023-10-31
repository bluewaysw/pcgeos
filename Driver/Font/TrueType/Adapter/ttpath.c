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
        FontHeader*            fontHeader;
        TransMatrix            transMatrix;
        TT_UShort              charIndex;
        WWFixedAsDWord         pointSize;
        XYValueAsDWord         cursorPos;


EC(     ECCheckGStateHandle( gstate ) );
EC(     ECCheckBounds( (void*)fontInfo ) );
EC(     ECCheckBounds( (void*)outlineEntry ) );
EC(     ECCheckBounds( (void*)firstEntry ) );
EC(     ECCheckMemHandle( varBlock ) );
EC(     ECCheckStack() );

        /* get trueTypeVar block */
        trueTypeVars = MemLock( varBlock );
EC(     ECCheckBounds( (void*)trueTypeVars ) );

        trueTypeOutline = LMemDerefHandles( MemPtrToHandle( (void*)fontInfo ), outlineEntry->OE_handle );
EC(     ECCheckBounds( (void*)trueTypeOutline ) );

        /* get pointer to FontHeader */
        fontHeader = LMemDerefHandles( MemPtrToHandle( (void*)fontInfo ), firstEntry->OE_handle );
EC(     ECCheckBounds( (void*)fontHeader ) );

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

        /* get pointsize for scaling */
        GrGetFont( gstate, &pointSize );

        /* we only perform steps 2 & 3 if the POSTSCRIPT flag wasn't passed */
        if( !(pathFlags & FGPF_POSTSCRIPT) )
        {
                word            translation = fontHeader->FH_accent + fontHeader->FH_ascent;
                WWFixedAsDWord  scale = GrUDivWWFixed( pointSize, ((dword)UNITS_PER_EM) << 16 );


                /* translate to baseline */
                GrApplyTranslation( gstate, 0, GrMulWWFixed( ((dword)translation) << 16, scale ) );

                /* flip on x-axis */ 
                GrApplyScale( gstate, 1L << 16, -1L << 16 );
        }

        /* calculate transformation matrix and apply it */
        CalcTransformMatrix( &transMatrix, pointSize, stylesToImplement );
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
 * SYNOPSIS:	  Convert glyphs outline into GrDraw..() calls.
 * 
 * PARAMETERS:    gstate                GStateHande in which the outline 
 *                                      of the character is written.
 *                *outline              Ptr. to glyphs outline.
 * 
 * RETURNS:       void
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


static void CalcTransformMatrix( TransMatrix*    transMatrix, 
                                 WWFixedAsDWord  pointSize, 
                                 TextStyle       stylesToImplement )
{
        WWFixedAsDWord scalePointSize = GrUDivWWFixed( pointSize, MakeWWFixed( STANDARD_GRIDSIZE ) );

        transMatrix->TM_e11.WWF_frac = FractionOf( scalePointSize );
        transMatrix->TM_e11.WWF_int  = IntegerOf( scalePointSize );
        transMatrix->TM_e12.WWF_frac = 0;
        transMatrix->TM_e12.WWF_int  = 0;
        transMatrix->TM_e21.WWF_frac = 0;
        transMatrix->TM_e21.WWF_int  = 0;
        transMatrix->TM_e22.WWF_frac = FractionOf( scalePointSize );
        transMatrix->TM_e22.WWF_int  = IntegerOf( scalePointSize );
        transMatrix->TM_e31.DWF_frac = 0;
        transMatrix->TM_e31.DWF_int  = 0;
        transMatrix->TM_e32.DWF_frac = 0;
        transMatrix->TM_e32.DWF_int  = 0;

        /* add styles if needed */
        if( stylesToImplement & TS_BOLD )
        {
                WWFixedAsDWord scaleScript = GrMulWWFixed( scalePointSize, BOLD_FACTOR );


                transMatrix->TM_e11.WWF_frac = FractionOf( scaleScript );
                transMatrix->TM_e11.WWF_int  = IntegerOf( scaleScript );
        }

        if( stylesToImplement & TS_ITALIC )
        {
                transMatrix->TM_e12.WWF_frac = FractionOf( ITALIC_FACTOR );
                transMatrix->TM_e12.WWF_int  = IntegerOf( ITALIC_FACTOR );
        }

        if( stylesToImplement & ( TS_SUBSCRIPT | TS_SUPERSCRIPT ) )
        {
                WWFixedAsDWord scaleScript = GrMulWWFixed( scalePointSize, SCRIPT_FACTOR );


                transMatrix->TM_e11.WWF_frac = FractionOf( scaleScript );
                transMatrix->TM_e11.WWF_int  = IntegerOf( scaleScript );
                transMatrix->TM_e22.WWF_frac = FractionOf( scaleScript );
                transMatrix->TM_e22.WWF_int  = IntegerOf( scaleScript );

                //TODO: tm_e31 und tm_e32 füllen
        }

        //TODO:
        //width & weight einarbeiten
}


/********************************************************************
 *                      WriteComment
 ********************************************************************
 * SYNOPSIS:	  Write glyphbox to gstate as comment.
 * 
 * PARAMETERS:    
 * 
 * RETURNS:       void   
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
        word            params[NUM_PARAMS];
        WWFixedAsDWord  scale = GrUDivWWFixed( ((dword)STANDARD_GRIDSIZE) << 16, ((dword)UNITS_PER_EM) << 16 );


        TT_Get_Glyph_Metrics( GLYPH, &GLYPH_METRICS );

        /* the glyph box must be scaled to 1000 units per em */
        params[0] = IntegerOf( GrMulWWFixed( ((dword)GLYPH_METRICS.advance) << 16, scale ) );
        params[1] = 0;
        params[2] = IntegerOf( GrMulWWFixed( ((dword)GLYPH_BBOX.xMin) << 16, scale ) );
        params[3] = IntegerOf( GrMulWWFixed( ((dword)GLYPH_BBOX.yMin) << 16, scale ) );
        params[4] = IntegerOf( GrMulWWFixed( ((dword)GLYPH_BBOX.xMax) << 16, scale ) );
        params[5] = IntegerOf( GrMulWWFixed( ((dword)GLYPH_BBOX.yMax) << 16, scale ) );

        GrComment( gstate, &params, NUM_PARAMS );
}
