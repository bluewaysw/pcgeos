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
#include <win.h>


/*
 * macros
 */

#define WW_FIXED_TO_WWFIXEDASDWORD( value )     ( (dword) ( (((dword)value.WWF_int) << 16) | value.WWF_frac ) )

#define ROUND_WWFIXED( value )    ( value & 0xffff ? ( value >> 16 ) + 1 : value >> 16 )

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

static void ConvertOutline( Handle            handle, 
                            TT_Outline*       outline, 
                            RenderFunctions*  functions );

static void _near MoveTo( Handle handle, TT_Vector* vec );

static void _near RegionPathMoveTo( Handle handle, TT_Vector* vec );

static void _near LineTo( Handle handle, TT_Vector* vec );

static void _near RegionPathLineTo( Handle handle, TT_Vector* vec );

static void _near ConicTo( Handle handle, TT_Vector* v_control, TT_Vector* vec );

static void _near RegionPathConicTo( Handle handle, TT_Vector* v_control, TT_Vector* vec );

static void WriteComment( TRUETYPE_VARS, GStateHandle gstate );

static void CalcScaleAndScaleOutline( TRUETYPE_VARS );

static void InitDriversTransformMatrix( TRUETYPE_VARS,
                                        TransformMatrix*  transMatrix,
                                        FontHeader*       fontHeader,
                                        WWFixedAsDWord    pointSize,
                                        TextStyle         stylesToImplement,
                                        Byte              width,
                                        Byte              weight );

static void CalcDriversTransformMatrix( TransformMatrix* transformMatrix, 
                                        GStateHandle gstate, 
                                        WindowHandle win );

extern void InitConvertHeader( TRUETYPE_VARS, FontHeader* fontHeader );


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
 *                *firstEntry           Ptr. to outline entry containing
 *                                      FontHeader.
 *                stylesToImplement     Text styles to be added.
 *                varBlock              Memory handle to var block.
 * 
 * RETURNS:       void  
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

        InitConvertHeader(trueTypeVars, fontHeader);

        TT_New_Glyph( FACE, &GLYPH );

        /* get TT char index */
        charIndex = TT_Char_Index( CHAR_MAP, GeosCharToUnicode( character ) );
        if( charIndex == 0 )
                goto Fail;

        /* write prologue */
        if( pathFlags & FGPF_SAVE_STATE )
                GrSaveState( gstate );

        /* load glyph and scale its outline to 1000 units per em */
        TT_Load_Glyph( INSTANCE, GLYPH, charIndex, 0 );
        TT_Get_Glyph_Outline( GLYPH, &OUTLINE );
        CalcScaleAndScaleOutline( trueTypeVars );

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

Fail:
        TrueType_Unlock_Face( trueTypeVars );
Fin:
        MemUnlock( varBlock );
}


/********************************************************************
 *                      TrueType_Gen_In_Region
 ********************************************************************
 * SYNOPSIS:	  Draw outline of the given charcode to region.
 * 
 * PARAMETERS:    gstate                Hande of gstate. 
 *                handle                Handle of region path.
 *                character             Character to build (GEOS Char).
 *                *fontInfo             Pointer to FontInfo structure.
 *                *outlineEntry         Ptr. to outline entry containing 
 *                                      TrueTypeOutlineEntry.
 *                *firstEntry           Ptr. to outline entry containing
 *                                      FontHeader.
 *                stylesToImplement     Text styles to be added.
 *                varBlock              Memory handle to var block.
 * 
 * RETURNS:       void
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
                        byte                 width,
                        byte                 weight,
			const FontInfo*      fontInfo, 
                        const OutlineEntry*  outlineEntry,
                        const OutlineEntry*  firstEntry,
                        TextStyle            stylesToImplement,
                        MemHandle            varBlock )
{
        TrueTypeVars*          trueTypeVars;
        FontHeader*            fontHeader;
        TrueTypeOutlineEntry*  trueTypeOutline;
        TT_UShort              charIndex;
        RenderFunctions        renderFunctions;
        TransformMatrix        transform;
        XYValueAsDWord         cursorPos;
        XYValueAsDWord         result;
        TT_Matrix              flipMatrix = HORIZONTAL_FLIP_MATRIX;


EC(     ECCheckGStateHandle( gstate ) );
EC(     ECCheckBounds( (void*) fontInfo ) );
EC(     ECCheckBounds( (void*) outlineEntry ) );
EC(     ECCheckMemHandle( varBlock ) );

        /* get trueTypeVar block */
        trueTypeVars = MemLock( varBlock );
EC(     ECCheckBounds( (void*)trueTypeVars ) );

        trueTypeOutline = LMemDerefHandles( MemPtrToHandle( (void*)fontInfo ), outlineEntry->OE_handle );
EC(     ECCheckBounds( (void*)trueTypeOutline ) );

        /* get pointer to FontHeader */
        fontHeader = LMemDerefHandles( MemPtrToHandle( (void*)fontInfo ), firstEntry->OE_handle );
EC(     ECCheckBounds( (void*)fontHeader ) );

        /* open face, create instance */
        if( TrueType_Lock_Face(trueTypeVars, trueTypeOutline) )
                goto Fin;

        InitConvertHeader(trueTypeVars, fontHeader);

        /* get TT char index */
        charIndex = TT_Char_Index( CHAR_MAP, GeosCharToUnicode( character ) );
        if( charIndex == 0 )
                goto Fail;

        /* load glyph */
        TT_New_Glyph( FACE, &GLYPH );
        TT_Load_Glyph( INSTANCE, GLYPH, charIndex, 0 );
        TT_Get_Glyph_Outline( GLYPH, &OUTLINE );

        /* store font matrix */
        InitDriversTransformMatrix( trueTypeVars, &transform, fontHeader, pointSize, stylesToImplement, width, weight );
        CalcDriversTransformMatrix( &transform, gstate, GrGetWinHandle( gstate ) );

        /* get current cursor position */
        cursorPos = GrGetCurPos( gstate );
        result = GrTransform( gstate, DWORD_X(cursorPos), DWORD_Y(cursorPos) );
        
        /* transform glyphs outline */
        TT_Transform_Outline( &OUTLINE, &transform.TM_matrix );
        TT_Transform_Outline( &OUTLINE, &flipMatrix );
        TT_Translate_Outline( &OUTLINE, DWORD_X(result) + transform.TM_heightX + transform.TM_scriptX, 
                                        DWORD_Y(result) + transform.TM_heightY + transform.TM_scriptY );
        /* set render functions */
        renderFunctions.Proc_MoveTo  = RegionPathMoveTo;
        renderFunctions.Proc_LineTo  = RegionPathLineTo;
        renderFunctions.Proc_ConicTo = RegionPathConicTo;

        ConvertOutline( regionPath, &OUTLINE, &renderFunctions );

        TT_Done_Glyph( GLYPH );

Fail:
        TrueType_Unlock_Face( trueTypeVars );
Fin:
        MemUnlock( varBlock );
}


/********************************************************************
 *                      ConvertOutline
 ********************************************************************
 * SYNOPSIS:	  Convert glyphs outline into GrDraw..() calls.
 * 
 * PARAMETERS:    handle                GStateHande or RegionPathHandle
 *                                      in which the outline of 
 *                                      character is written.
 *                *outline              Ptr. to glyphs outline.
 * 
 * RETURNS:       void
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      22/10/23  JK        Initial Revision
 *******************************************************************/

#define CURVE_TAG_ON            0x01
#define CURVE_TAG_CONIC         0x00
static void ConvertOutline( Handle handle, TT_Outline* outline, RenderFunctions* functions )
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

        (*functions->Proc_MoveTo)( handle, &v_start );

        while ( point < limit )
        {
                ++point;
                ++tags;

                switch ( *tags & 1 )
                {
                        case CURVE_TAG_ON:
                        {
                                (*functions->Proc_LineTo)( handle, point );
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
                                                (*functions->Proc_ConicTo)( handle, &v_control, &vec );
                                                continue;
                                        }

                                        v_middle.x = ( v_control.x + vec.x ) >> 1;
                                        v_middle.y = ( v_control.y + vec.y ) >> 1;

                                        (*functions->Proc_ConicTo)( handle, &v_control, &v_middle );

                                        v_control = vec;
                                        goto Do_Conic;
                                }

                                (*functions->Proc_ConicTo)( handle, &v_control, &v_start );
                                break;
                        }
                }

                /* close the contour with a line segment */
                (*functions->Proc_LineTo)( handle, &v_start );
        }
}


/********************************************************************
 *                      MoveTo
 ********************************************************************
 * SYNOPSIS:	  Change current position.
 * 
 * PARAMETERS:    handle                GStateHandle in which current 
 *                                      position is changed.
 *                *vec                  Ptr to Vector to new position.
 * 
 * RETURNS:       void 
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      18/11/23  JK        Initial Revision
 *******************************************************************/

static void _near MoveTo( Handle handle, TT_Vector* vec )
{
        GrMoveTo( (GStateHandle) handle, vec->x, vec->y );
}


/********************************************************************
 *                      RegionPathMoveTo
 ********************************************************************
 * SYNOPSIS:	  Change current position.
 * 
 * PARAMETERS:    handle                Handle to region path in which 
 *                                      current position is changed.
 *                *vec                  Ptr to Vector to new position.
 * 
 * RETURNS:       void
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      14/03/24  JK        Initial Revision
 *******************************************************************/

static void _near RegionPathMoveTo( Handle handle, TT_Vector* vec )
{
        GrRegionPathMovePen( handle, vec->x, vec->y );
}


/********************************************************************
 *                      LineTo
 ********************************************************************
 * SYNOPSIS:	  Draw line to given position.
 * 
 * PARAMETERS:    handle                GStateHandle in which the line 
 *                                      is drawed.
 *                *vec                  Ptr. to Vector of end position.
 * 
 * RETURNS:       void 
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      18/11/23  JK        Initial Revision
 *******************************************************************/

static void _near LineTo( Handle handle, TT_Vector* vec )
{
        GrDrawLineTo( (GStateHandle) handle, vec->x, vec->y );
}


/********************************************************************
 *                      RegionPathLineTo
 ********************************************************************
 * SYNOPSIS:	  Draw line to given position.
 * 
 * PARAMETERS:    handle                Handle to region path in which 
 *                                      the line is drawed.
 *                *vec                  Ptr. to Vector of end position.
 * 
 * RETURNS:       void
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      14/03/24  JK        Initial Revision
 *******************************************************************/

static void _near RegionPathLineTo( Handle handle, TT_Vector* vec )
{
        GrRegionPathDrawLineTo( handle, vec->x, vec->y );
}


/********************************************************************
 *                      ConicTo
 ********************************************************************
 * SYNOPSIS:	  Draw conic curve to given position.
 * 
 * PARAMETERS:    handle                GStateHandle in which the curve 
 *                                      is drawed.
 *                *v_control            Vector with control point.
 *                *vec                  Vector of new position.
 * 
 * RETURNS:       void
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      18/11/23  JK        Initial Revision
 *******************************************************************/

static void _near ConicTo( Handle handle, TT_Vector* v_control, TT_Vector* vec )
{
        Point p[3];


        p[0].P_x = v_control->x;
        p[0].P_y = v_control->y;
        p[1].P_x = p[2].P_x = vec->x;
        p[1].P_y = p[2].P_y = vec->y;

        GrDrawCurveTo( (GStateHandle) handle, p );
}


/********************************************************************
 *                      RegionPathConicTo
 ********************************************************************
 * SYNOPSIS:	  Draw conic curve to given position.
 * 
 * PARAMETERS:    handle                Handle to region path in which 
 *                                      the curve is drawed.
 *                *v_control            Vector with control point.
 *                *vec                  Vector of new position.
 * 
 * RETURNS:       void
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      14/03/24  JK        Initial Revision
 *******************************************************************/

static void _near RegionPathConicTo( Handle handle, TT_Vector* v_control, TT_Vector* vec )
{
        Point p[3];


        p[0].P_x = v_control->x;
        p[0].P_y = v_control->y;
        p[1].P_x = p[2].P_x = vec->x;
        p[1].P_y = p[2].P_y = vec->y;

        GrRegionPathDrawCurveTo( handle, p );
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
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      14/10/23  JK        Initial Revision
 *******************************************************************/

#define NUM_PARAMS              6
static void WriteComment( TRUETYPE_VARS, GStateHandle gstate )
{
        word            params[NUM_PARAMS];
       

        TT_Get_Glyph_Metrics( GLYPH, &GLYPH_METRICS );

        params[0] = SCALE_WORD( GLYPH_METRICS.advance, SCALE_WIDTH ) >> 16;
        params[1] = 0;
        params[2] = SCALE_WORD( GLYPH_BBOX.xMin, SCALE_WIDTH ) >> 16;
        params[3] = SCALE_WORD( GLYPH_BBOX.yMin, SCALE_HEIGHT ) >> 16;
        params[4] = SCALE_WORD( GLYPH_BBOX.xMax, SCALE_WIDTH ) >> 16;
        params[5] = SCALE_WORD( GLYPH_BBOX.yMax, SCALE_HEIGHT ) >> 16;

        GrComment( gstate, params, NUM_PARAMS * sizeof( word ) );
}


/********************************************************************
 *                      CalcScaleAndScaleOutline
 ********************************************************************
 * SYNOPSIS:	  Calculate scale factors to 1000 units per em and 
 *                scale current outline.
 * 
 * PARAMETERS:    TRUETYPE_VARS         Cached variables needed by driver.
 * 
 * RETURNS:       void   
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      18/11/23  JK        Initial Revision
 *******************************************************************/

static void CalcScaleAndScaleOutline( TRUETYPE_VARS )
{
        TT_Matrix      scaleMatrix = { 0, 0, 0, 0 };


        SCALE_HEIGHT = SCALE_WIDTH = scaleMatrix.xx = scaleMatrix.yy = GrUDivWWFixed( STANDARD_GRIDSIZE, UNITS_PER_EM );

        TT_Transform_Outline( &OUTLINE, &scaleMatrix );
}


/********************************************************************
 *                      InitDriversTransformMatrix
 ********************************************************************
 * SYNOPSIS:	  Initialize fontdrivers transform matrix with pointsize, 
 *                stytes to implement, width and weight.
 * 
 * PARAMETERS:    TRUETYPE_VARS         Cached variables needed by driver.
 *                *transmatrix          Ptr. to drivers transformation 
 *                                      matrix to fill.
 *                *fontHeader           Ptr to FontHeader structure.
 *                pointsize             Desired point size.
 *                stylesToImplement     Styles that must be added.
 *                width                 Desired glyph width.
 *                weight                Desired glyph weight.
 * 
 * RETURNS:       void   
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      19/02/23  JK        Initial Revision
 *******************************************************************/

static void InitDriversTransformMatrix( TRUETYPE_VARS,
                                        TransformMatrix*  transMatrix,
                                        FontHeader*       fontHeader,
                                        WWFixedAsDWord    pointSize,
                                        TextStyle         stylesToImplement,
                                        Byte              width,
                                        Byte              weight )
{
        WWFixedAsDWord scaleFactor;


EC(     ECCheckBounds( (void*)transMatrix ) );
EC(     ECCheckBounds( (void*)trueTypeVars ) );


        /* calculate scale factor for pointsize */
        scaleFactor = GrUDivWWFixed( pointSize, MakeWWFixed( UNITS_PER_EM ) );

        /* initilize drivers tranformation matrix */
        transMatrix->TM_matrix.xx = scaleFactor;
        transMatrix->TM_matrix.xy = 0L;
        transMatrix->TM_matrix.yx = 0L;
        transMatrix->TM_matrix.yy = scaleFactor;
        transMatrix->TM_heightX   = 0L;
        transMatrix->TM_heightY   = ROUND_WWFIXED( SCALE_WORD( fontHeader->FH_ascent + fontHeader->FH_accent, scaleFactor ) ) + BASELINE_CORRECTION;
        transMatrix->TM_scriptX   = 0L;
        transMatrix->TM_scriptY   = 0L;

        /* fake bold style       */
        if( stylesToImplement & TS_BOLD )
                transMatrix->TM_matrix.xx = GrMulWWFixed( BOLD_FACTOR, transMatrix->TM_matrix.xx );

        /* fake italic style       */
        if( stylesToImplement & TS_ITALIC )
                transMatrix->TM_matrix.yx = NEGATVE_ITALIC_FACTOR;

        /* width and weight */
        if( width != FWI_MEDIUM )
                transMatrix->TM_matrix.xx = MUL_100_WWFIXED( transMatrix->TM_matrix.xx, width );

        if( weight != FW_NORMAL )
                transMatrix->TM_matrix.xx = MUL_100_WWFIXED( transMatrix->TM_matrix.xx, weight );

        /* fake script style      */
        if( stylesToImplement & ( TS_SUBSCRIPT | TS_SUPERSCRIPT ) )
        {      
                WWFixedAsDWord scriptBaseline = GrMulWWFixed( MakeWWFixed( fontHeader->FH_height + fontHeader->FH_baseAdjust ), scaleFactor ); 


                transMatrix->TM_matrix.xx = GrMulWWFixed( transMatrix->TM_matrix.xx, SCRIPT_FACTOR );
                transMatrix->TM_matrix.yy = GrMulWWFixed( transMatrix->TM_matrix.yy, SCRIPT_FACTOR );

                if( stylesToImplement & TS_SUBSCRIPT )
                {
                        //TODO: Is rounding necessary here?
                        transMatrix->TM_scriptY = GrMulWWFixed( scriptBaseline, SUBSCRIPT_OFFSET ) >> 16;
                }
                else
                {
                        //TODO: Is rounding necessary here?
                        transMatrix->TM_scriptY = ( GrMulWWFixed( scriptBaseline, SUPERSCRIPT_OFFSET ) - 
                                                GrMulWWFixed( WORD_TO_WWFIXEDASDWORD( fontHeader->FH_accent + fontHeader->FH_ascent + fontHeader->FH_baseAdjust ), scaleFactor ) >> 16 );
                }
        }

}


/********************************************************************
 *                      CalcDriversTransformMatrix
 ********************************************************************
 * SYNOPSIS:	  Calculate fontmatrix for rotation and document scale.
 * 
 * PARAMETERS:    *transformMatrix      Ptr. to drivers tranformation 
 *                                      matrix to fill.
 *                gstate                GStateHande to get graphics 
 *                                      transformation matrix.
 *                win                   WindowHandle to get windows
 *                                      transformation matrix.
 * 
 * RETURNS:       void   
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      26/04/24  JK        Initial Revision
 *******************************************************************/

static void CalcDriversTransformMatrix( TransformMatrix* transformMatrix, GStateHandle gstate, WindowHandle win )
{
        TransMatrix     windowMatrix;
        TransMatrix     graphicMatrix;
        WWFixedAsDWord  temp_e11, temp_e12, temp_e21, temp_e22;


EC(     ECCheckBounds( transformMatrix ) );
EC(     ECCheckGStateHandle( gstate) );


        if( win )
        {
EC(             ECCheckWindowHandle( win ) );
                WinGetTransform( win, &windowMatrix );
        }
        else
        {
                windowMatrix.TM_e11.WWF_int  = 1;
                windowMatrix.TM_e11.WWF_frac = 0;
                windowMatrix.TM_e12.WWF_int  = 0;
                windowMatrix.TM_e12.WWF_frac = 0;
                windowMatrix.TM_e21.WWF_int  = 0;
                windowMatrix.TM_e21.WWF_frac = 0;
                windowMatrix.TM_e22.WWF_int  = 1;
                windowMatrix.TM_e22.WWF_frac = 0;
        }

        GrGetTransform( gstate, &graphicMatrix );

        temp_e11 = GrMulWWFixed( transformMatrix->TM_matrix.xx, WWFIXED_TO_WWFIXEDASDWORD( graphicMatrix.TM_e11 ) ) 
                        + GrMulWWFixed( transformMatrix->TM_matrix.xy, WWFIXED_TO_WWFIXEDASDWORD( graphicMatrix.TM_e21 ) );
        temp_e12 = GrMulWWFixed( transformMatrix->TM_matrix.xx, WWFIXED_TO_WWFIXEDASDWORD( graphicMatrix.TM_e12 ) ) 
                        + GrMulWWFixed( transformMatrix->TM_matrix.xy, WWFIXED_TO_WWFIXEDASDWORD( graphicMatrix.TM_e22 ) );
        temp_e21 = GrMulWWFixed( transformMatrix->TM_matrix.yx, WWFIXED_TO_WWFIXEDASDWORD( graphicMatrix.TM_e11 ) ) 
                        + GrMulWWFixed( transformMatrix->TM_matrix.yy, WWFIXED_TO_WWFIXEDASDWORD( graphicMatrix.TM_e21 ) );
        temp_e22 = GrMulWWFixed( transformMatrix->TM_matrix.yx, WWFIXED_TO_WWFIXEDASDWORD( graphicMatrix.TM_e12 ) ) 
                        + GrMulWWFixed( transformMatrix->TM_matrix.yy, WWFIXED_TO_WWFIXEDASDWORD( graphicMatrix.TM_e22 ) );

        transformMatrix->TM_matrix.xx = GrMulWWFixed( temp_e11, WWFIXED_TO_WWFIXEDASDWORD( windowMatrix.TM_e11 ) ) 
                        + GrMulWWFixed( temp_e12, WWFIXED_TO_WWFIXEDASDWORD( windowMatrix.TM_e21 ) );
        transformMatrix->TM_matrix.xy = GrMulWWFixed( temp_e11, WWFIXED_TO_WWFIXEDASDWORD( windowMatrix.TM_e12 ) ) 
                        + GrMulWWFixed( temp_e12, WWFIXED_TO_WWFIXEDASDWORD( windowMatrix.TM_e22 ) );
        transformMatrix->TM_matrix.yx = GrMulWWFixed( temp_e21, WWFIXED_TO_WWFIXEDASDWORD( windowMatrix.TM_e11 ) ) 
                        + GrMulWWFixed( temp_e22, WWFIXED_TO_WWFIXEDASDWORD( windowMatrix.TM_e21 ) );
        transformMatrix->TM_matrix.yy = GrMulWWFixed( temp_e21, WWFIXED_TO_WWFIXEDASDWORD( windowMatrix.TM_e12 ) ) 
                        + GrMulWWFixed( temp_e22, WWFIXED_TO_WWFIXEDASDWORD( windowMatrix.TM_e22 ) );


        transformMatrix->TM_heightX = INTEGER_OF_WWFIXEDASDWORD( GrMulWWFixed( 
                        WORD_TO_WWFIXEDASDWORD( transformMatrix->TM_heightY ), WWFIXED_TO_WWFIXEDASDWORD( graphicMatrix.TM_e21 ) ) );
        transformMatrix->TM_heightY = INTEGER_OF_WWFIXEDASDWORD( GrMulWWFixed( 
                        WORD_TO_WWFIXEDASDWORD( transformMatrix->TM_heightY ), WWFIXED_TO_WWFIXEDASDWORD( graphicMatrix.TM_e22 ) ) );
}

