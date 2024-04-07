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

/*
 * types
 */

typedef void  Function_MoveTo( Handle han, TT_Vector* vec );

typedef void  Function_LineTo( Handle han, TT_Vector* vec );

typedef void  Function_ConicTo( Handle han, TT_Vector* v_control, TT_Vector* vec );


/*
 * structures
 */

typedef struct 
{
      Function_MoveTo  _near * Proc_MoveTo;
      Function_LineTo  _near * Proc_LineTo;
      Function_ConicTo _near * Proc_ConicTo;
} RenderFunctions;


/*
 * prototypes
 */

static void CalcTransformMatrix( TransMatrix*    transMatrix, 
                                 WWFixedAsDWord  pointSize, 
                                 TextStyle       stylesToImplement );

static void ConvertOutline( GStateHandle      gstate, 
                            TT_Outline*       outline, 
                            RenderFunctions*  functions );

static void _near MoveTo( GStateHandle gstate, TT_Vector* vec );

static void _near RegionPathMoveTo( Handle regionHandle, TT_Vector* vec );

static void _near LineTo( GStateHandle gstate, TT_Vector* vec );

static void _near RegionPathLineTo( Handle regionHandle, TT_Vector* vec );

static void _near ConicTo( GStateHandle gstate, TT_Vector* v_control, TT_Vector* vec );

static void _near RegionPathConicTo( GStateHandle gstate, TT_Vector* v_control, TT_Vector* vec );

static void _near RegionPathInit( Handle regionHandle, word maxY );

static void _near WriteComment( TRUETYPE_VARS, GStateHandle gstate );

static void ScaleOutline( TRUETYPE_VARS );

static void StoreFontMatrix( TRUETYPE_VARS,
                             TT_Matrix*      transMatrix,
                             WWFixedAsDWord  pointSize );


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
        word                   baseline;
        RenderFunctions        renderFunctions;


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
        ScaleOutline( trueTypeVars );

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

        /* calculate baseline for further use */
        baseline = fontHeader->FH_accent + fontHeader->FH_ascent;

        /* translate by current cursor position */
        cursorPos = GrGetCurPos( gstate );
        GrApplyTranslationDWord( gstate, DWORD_X( cursorPos ), DWORD_Y( cursorPos ) );

        /* get pointsize for scaling */
        GrGetFont( gstate, &pointSize );

        /* we only perform steps 2 & 3 if the POSTSCRIPT flag wasn't passed */
        if( !(pathFlags & FGPF_POSTSCRIPT) )
        {
                WWFixedAsDWord  scale = GrUDivWWFixed( pointSize, ((dword)UNITS_PER_EM) << 16 );


                /* translate to baseline */
                GrApplyTranslation( gstate, 0, GrMulWWFixed( ((dword)baseline) << 16, scale ) );

                /* flip on x-axis */ 
                GrApplyScale( gstate, 1L << 16, -1L << 16 );
        }

        /* calculate transformation matrix and apply it */
        CalcTransformMatrix( &transMatrix, pointSize, stylesToImplement );
        GrApplyTransform( gstate, &transMatrix );

        /* set render functions */
        renderFunctions.Proc_MoveTo  = MoveTo;
        renderFunctions.Proc_LineTo  = LineTo;
        renderFunctions.Proc_ConicTo = ConicTo;
        
        /* convert outline into GrDraw...() calls */
        ConvertOutline( gstate, &OUTLINE, &renderFunctions );

        /* write epilogue */
        if( pathFlags & FGPF_SAVE_STATE )
                GrRestoreState( gstate );

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
 * RETURNS:       void
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
                        TextStyle            stylesToImplement,
                        MemHandle            varBlock )
{
        TrueTypeVars*          trueTypeVars;
        TrueTypeOutlineEntry*  trueTypeOutline;
        TT_UShort              charIndex;
        XYValueAsDWord         cursorPos;
        TT_Matrix              transMatrix;
        RenderFunctions        renderFunctions;


EC(     ECCheckGStateHandle( gstate ) );
EC(     ECCheckBounds( (void*) fontInfo ) );
EC(     ECCheckBounds( (void*) outlineEntry ) );
EC(     ECCheckMemHandle( varBlock ) );

        /* get trueTypeVar block */
        trueTypeVars = MemLock( varBlock );
EC(     ECCheckBounds( (void*)trueTypeVars ) );

        trueTypeOutline = LMemDerefHandles( MemPtrToHandle( (void*)fontInfo ), outlineEntry->OE_handle );
EC(     ECCheckBounds( (void*)trueTypeOutline ) );

        /* open face, create instance and glyph */
        if( TrueType_Lock_Face(trueTypeVars, trueTypeOutline) )
                goto Fin;

        TT_New_Glyph( FACE, &GLYPH );
        TT_Load_Glyph( INSTANCE, GLYPH, charIndex, 0 );
        TT_Get_Glyph_Outline( GLYPH, &OUTLINE );

        /* get TT char index */
        charIndex = TT_Char_Index( CHAR_MAP, GeosCharToUnicode( character ) );

        /* store font matrix */
        StoreFontMatrix( trueTypeVars, &transMatrix, pointSize );

        /* translate by current cursor position */
        cursorPos = GrGetCurPos( gstate );
        GrApplyTranslationDWord( gstate, DWORD_X( cursorPos ), DWORD_Y( cursorPos ) );

        /* set render functions */
        renderFunctions.Proc_MoveTo  = RegionPathMoveTo;
        renderFunctions.Proc_LineTo  = RegionPathLineTo;
        renderFunctions.Proc_ConicTo = RegionPathConicTo;

        //TODO: init region path
        //GrRegionPathInit( regionPath, 20 );

        //TODO: render glyph as regionpath

        //TEST: hart verdrahtetes Glyph (Minus)
        GrRegionPathMovePen( regionPath, 248, 296 );

        GrRegionPathDrawLineTo( regionPath, 248, 308 );
        GrRegionPathDrawLineTo( regionPath, 284, 308 );
        GrRegionPathDrawLineTo( regionPath, 284, 296 );
        GrRegionPathDrawLineTo( regionPath, 248, 296 );
        //ENDE TEST: hart verdrahtetes Glyph

Fail:
        TT_Done_Glyph( GLYPH );

Fin:
        MemUnlock( varBlock );
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

#define CURVE_TAG_ON            0x01
#define CURVE_TAG_CONIC         0x00
static void ConvertOutline( GStateHandle gstate, TT_Outline* outline, RenderFunctions* functions )
{
        TT_Vector   v_last;
        TT_Vector   v_control;
        TT_Vector   v_start;

        TT_Vector*  point;
        TT_Vector*  limit;
        char*       tags;

        TT_Int   n;
        TT_Int   first;
        TT_Int   last;


EC(     ECCheckBounds( (void*)outline ) );
EC(     ECCheckGStateHandle( gstate ) );

        last = -1;
        for ( n = 0; n < outline->n_contours; ++n )
        {
                first = last + 1;
                last  = outline->contours[n];
                if ( last < first )
                        return;

                limit     = outline->points + last;
                v_start   = outline->points[first];
                v_last    = outline->points[last];

                v_control = v_start;

                point = outline->points + first;
                tags  = outline->flags  + first;

                /* check first point to determine origin */
                if ( *tags & CURVE_TAG_CONIC )
                {
                        /* first point is conic control. Yes, this happens. */
                        if ( outline->flags[last] & CURVE_TAG_ON )
                        {
                                /* start at last point if it is on the curve */
                                v_start = v_last;
                                --limit;
                        }
                        else
                        {
                                /* if both first and last points are conic,         */
                                /* start at their middle and record its position    */
                                v_start.x = ( v_start.x + v_last.x ) >> 1;
                                v_start.y = ( v_start.y + v_last.y ) >> 1;
                        }
                --point;
                --tags;
        }

        (*functions->Proc_MoveTo)( gstate, &v_start );

        while ( point < limit )
        {
                ++point;
                ++tags;

                switch ( *tags & 1 )
                {
                        case CURVE_TAG_ON:
                        {
                                (*functions->Proc_LineTo)( gstate, point );
                                continue;
                        }

                        case CURVE_TAG_CONIC:  /* consume conic arcs */
                                v_control.x = point->x;
                                v_control.y = point->y;

                        Do_Conic:
                                if ( point < limit )
                                {
                                        TT_Vector  vec;
                                        TT_Vector  v_middle;


                                        ++point;
                                        ++tags;

                                        vec.x = point->x;
                                        vec.y = point->y;

                                        if (  *tags & CURVE_TAG_ON )
                                        {
                                                (*functions->Proc_ConicTo)( gstate, &v_control, &vec );
                                                continue;
                                        }

                                        v_middle.x = ( v_control.x + vec.x ) >> 1;
                                        v_middle.y = ( v_control.y + vec.y ) >> 1;

                                        (*functions->Proc_ConicTo)( gstate, &v_control, &v_middle );

                                        v_control = vec;
                                        goto Do_Conic;
                                }

                                (*functions->Proc_ConicTo)( gstate, &v_control, &v_start );
                                break;
                        }
                }

                /* close the contour with a line segment */
                (*functions->Proc_LineTo)( gstate, &v_start );
        }
}


/********************************************************************
 *                      MoveTo
 ********************************************************************
 * SYNOPSIS:	  Change current position.
 * 
 * PARAMETERS:    gstate                Handle in which the position is changed.
 *                *vec                  Ptr to Vector to new position.
 * 
 * RETURNS:       void
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      18/11/23  JK        Initial Revision
 *******************************************************************/

static void _near MoveTo( GStateHandle gstate, TT_Vector* vec )
{
        GrMoveTo( gstate, vec->x, vec->y );
}


/********************************************************************
 *                      RegionPathMoveTo
 ********************************************************************
 * SYNOPSIS:	  Change current position.
 * 
 * PARAMETERS:    regionHandle          Handle to regionpath in which 
 *                                      the position is changed.
 *                *vec                  Ptr to Vector to new position.
 * 
 * RETURNS:       void
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      14/03/24  JK        Initial Revision
 *******************************************************************/

static void _near RegionPathMoveTo( Handle regionHandle, TT_Vector* vec )
{
        GrRegionPathMovePen( regionHandle, vec->x, vec->y );
}


/********************************************************************
 *                      LineTo
 ********************************************************************
 * SYNOPSIS:	  Draw line to given position.
 * 
 * PARAMETERS:    gstate                Handle in which the line is drawed.
 *                *vec                  Ptr. to Vector of end position.
 * 
 * RETURNS:       void
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      18/11/23  JK        Initial Revision
 *******************************************************************/

static void _near LineTo( GStateHandle gstate, TT_Vector* vec )
{
        GrDrawLineTo( gstate, vec->x, vec->y );
}


/********************************************************************
 *                      RegionPathLineTo
 ********************************************************************
 * SYNOPSIS:	  Draw line to given position.
 * 
 * PARAMETERS:    regionHandle          Handle to regionpath in which 
 *                                      the line is drawed.
 *                *vec                  Ptr. to Vector of end position.
 * 
 * RETURNS:       void
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      14/03/24  JK        Initial Revision
 *******************************************************************/

static void _near RegionPathLineTo( Handle regionHandle, TT_Vector* vec )
{
        GrRegionPathDrawLineTo( regionHandle, vec->x, vec->y );
}


/********************************************************************
 *                      ConicTo
 ********************************************************************
 * SYNOPSIS:	  Draw conic curve to given position.
 * 
 * PARAMETERS:    gstate                Handle in which the curve is drawed.
 *                *v_control            Vector with control point.
 *                *vec                  Vector of new position.
 * 
 * RETURNS:       void
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      18/11/23  JK        Initial Revision
 *******************************************************************/

static void _near ConicTo( GStateHandle gstate, TT_Vector* v_control, TT_Vector* vec )
{
        Point p[3];


        p[0].P_x = v_control->x;
        p[0].P_y = v_control->y;
        p[1].P_x = p[2].P_x = vec->x;
        p[1].P_y = p[2].P_y = vec->y;

        GrDrawCurveTo( gstate, p );
}


/********************************************************************
 *                      RegionPathConicTo
 ********************************************************************
 * SYNOPSIS:	  Draw conic curve to given position.
 * 
 * PARAMETERS:    regionHandle          Handle to regionpath in which 
 *                                      the curve is drawed.
 *                *v_control            Vector with control point.
 *                *vec                  Vector of new position.
 * 
 * RETURNS:       void
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      14/03/24  JK        Initial Revision
 *******************************************************************/

static void _near RegionPathConicTo( Handle regionHandle, TT_Vector* v_control, TT_Vector* vec )
{
        Point p[3];


        p[0].P_x = v_control->x;
        p[0].P_y = v_control->y;
        p[1].P_x = p[2].P_x = vec->x;
        p[1].P_y = p[2].P_y = vec->y;

        GrRegionPathDrawCurveTo( regionHandle, p );
}


/********************************************************************
 *                      RegionPathInit
 ********************************************************************
 * SYNOPSIS:	  Initialize region path.
 * 
 * PARAMETERS:    regionHandle          Handle to regionpath in which 
 *                                      the curve is drawed.
 *                maxY                  Max value for y.
 * 
 * RETURNS:       void
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      14/03/24  JK        Initial Revision
 *******************************************************************/

static void _near RegionPathInit( Handle regionHandle, word maxY )
{
        GrRegionPathInit( regionHandle, maxY );
}


/********************************************************************
 *                      CalcTransformMatrix
 ********************************************************************
 * SYNOPSIS:	  Calculate tranformation matrix for scale and styles.
 * 
 * PARAMETERS:    *transmatrix          Ptr. to transformation matrix
 *                                      to fill.
 *                pointsize             Desired point size.
 *                stylesToImplement     Styles that must be added.
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

static void CalcTransformMatrix( TransMatrix*    transMatrix, 
                                 WWFixedAsDWord  pointSize, 
                                 TextStyle       stylesToImplement )
{
        WWFixedAsDWord scaleFactor = GrUDivWWFixed( pointSize, MakeWWFixed( STANDARD_GRIDSIZE ) );

        transMatrix->TM_e11.WWF_frac = FractionOf( scaleFactor );
        transMatrix->TM_e11.WWF_int  = IntegerOf( scaleFactor );
        transMatrix->TM_e12.WWF_frac = 0;
        transMatrix->TM_e12.WWF_int  = 0;
        transMatrix->TM_e21.WWF_frac = 0;
        transMatrix->TM_e21.WWF_int  = 0;
        transMatrix->TM_e22.WWF_frac = FractionOf( scaleFactor );
        transMatrix->TM_e22.WWF_int  = IntegerOf( scaleFactor );
        transMatrix->TM_e31.DWF_frac = 0;
        transMatrix->TM_e31.DWF_int  = 0;
        transMatrix->TM_e32.DWF_frac = 0;
        transMatrix->TM_e32.DWF_int  = 0;

        /* add styles if needed (order of processed styles is important) */
        if( stylesToImplement & TS_BOLD )
        {
                scaleFactor = GrMulWWFixed( scaleFactor, BOLD_FACTOR );

                transMatrix->TM_e11.WWF_frac = FractionOf( scaleFactor );
                transMatrix->TM_e11.WWF_int  = IntegerOf( scaleFactor );
        }

        if( stylesToImplement & ( TS_SUBSCRIPT | TS_SUPERSCRIPT ) )
        {
                WWFixedAsDWord translation;


                scaleFactor = GrMulWWFixed( scaleFactor, SCRIPT_FACTOR );

                transMatrix->TM_e11.WWF_frac = transMatrix->TM_e22.WWF_frac = FractionOf( scaleFactor );
                transMatrix->TM_e11.WWF_int  = transMatrix->TM_e22.WWF_int  = IntegerOf( scaleFactor );

                if( stylesToImplement & TS_SUPERSCRIPT )
                        translation = GrMulWWFixed( SUPERSCRIPT_OFFSET, (dword)STANDARD_GRIDSIZE << 16 );

                if( stylesToImplement & TS_SUBSCRIPT )
                        translation = -GrMulWWFixed( SUBSCRIPT_OFFSET, (dword)STANDARD_GRIDSIZE << 16 );

                transMatrix->TM_e32.DWF_frac = FractionOf( translation );
                transMatrix->TM_e32.DWF_int  = IntegerOf( translation );
        }

        if( stylesToImplement & TS_ITALIC )
        {
                WWFixedAsDWord shearFactor = GrMulWWFixed( scaleFactor, ITALIC_FACTOR );


                transMatrix->TM_e21.WWF_frac = FractionOf( shearFactor );
                transMatrix->TM_e21.WWF_int  = IntegerOf( shearFactor );
        }
}


/********************************************************************
 *                      WriteComment
 ********************************************************************
 * SYNOPSIS:	  Write glyphbox to gstate as comment.
 * 
 * PARAMETERS:    TRUETYPE_VARS         Cached variables needed by driver.
 *                gstate                GStateHande in which the comment 
 *                                      is written.
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
static void _near WriteComment( TRUETYPE_VARS, GStateHandle gstate )
{
        word            params[NUM_PARAMS];
       

        TT_Get_Glyph_Metrics( GLYPH, &GLYPH_METRICS );

        params[0] = GLYPH_METRICS.advance;
        params[1] = 0;
        params[2] = GLYPH_BBOX.xMin;
        params[3] = GLYPH_BBOX.yMin;
        params[4] = GLYPH_BBOX.xMax;
        params[5] = GLYPH_BBOX.yMax;

        GrComment( gstate, params, NUM_PARAMS * sizeof( word ) );
}


/********************************************************************
 *                      ScaleOutline
 ********************************************************************
 * SYNOPSIS:	  Scale current outline to 1000 untits per em.
 * 
 * PARAMETERS:    TRUETYPE_VARS         Cached variables needed by driver.
 * 
 * RETURNS:       void   
 * 
 * STRATEGY:      
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      18/11/23  JK        Initial Revision
 *******************************************************************/

static void ScaleOutline( TRUETYPE_VARS )
{
        TT_Matrix      scaleMatrix = { 0, 0, 0, 0 };


        scaleMatrix.xx = scaleMatrix.yy = GrUDivWWFixed( STANDARD_GRIDSIZE, UNITS_PER_EM );

        TT_Transform_Outline( &OUTLINE, &scaleMatrix );
}


/********************************************************************
 *                      StoreFontMatrix
 ********************************************************************
 * SYNOPSIS:	  
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
 *      19/02/23  JK        Initial Revision
 *******************************************************************/

static void StoreFontMatrix( TRUETYPE_VARS,
                             TT_Matrix*      transMatrix,
                             WWFixedAsDWord  pointSize )
{
        WWFixedAsDWord scaleFactor = GrUDivWWFixed( pointSize, MakeWWFixed( UNITS_PER_EM ) );


        transMatrix->xx = scaleFactor;
        transMatrix->xy = 0L;
        transMatrix->yx = 0L;
        transMatrix->yy = scaleFactor;
}
