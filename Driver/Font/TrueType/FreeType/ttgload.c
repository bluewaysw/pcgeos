/*******************************************************************
 *
 *  ttgload.c                                                   1.0
 *
 *    TrueType Glyph Loader.
 *
 *  Copyright 1996-1999 by
 *  David Turner, Robert Wilhelm, and Werner Lemberg.
 *
 *  This file is part of the FreeType project, and may only be used
 *  modified and distributed under the terms of the FreeType project
 *  license, LICENSE.TXT.  By continuing to use, modify, or distribute
 *  this file you indicate that you have read the license and
 *  understand and accept it fully.
 *
 ******************************************************************/

#include "tttypes.h"
#include "ttcalc.h"
#include "ttfile.h"

#include "tttables.h"
#include "ttobjs.h"
#include "ttgload.h"

#include "ttmemory.h"
#include "tttags.h"
#include "ttload.h"

/* required by the tracing mode */
#undef  TT_COMPONENT
#define TT_COMPONENT  trace_gload


/* composite font flags */

#define ARGS_ARE_WORDS       0x001
#define ARGS_ARE_XY_VALUES   0x002
#define ROUND_XY_TO_GRID     0x004
#define WE_HAVE_A_SCALE      0x008
/* reserved                  0x010 */
#define MORE_COMPONENTS      0x020
#define WE_HAVE_AN_XY_SCALE  0x040
#define WE_HAVE_A_2X2        0x080
#define WE_HAVE_INSTR        0x100
#define USE_MY_METRICS       0x200


/********************************************************/
/* Return horizontal or vertical metrics in font units  */
/* for a given glyph.  The metrics are the left side    */
/* bearing (resp. top side bearing) and advance width   */
/* (resp. advance height).                              */
/*                                                      */
/* This function will much probably move to another     */
/* component in the short future, but I haven't decided */
/* which yet...                                         */

  LOCAL_FUNC
  void  TT_Get_Metrics( TT_Horizontal_Header*  header,
                        UShort                 index,
                        Short*                 bearing,
                        UShort*                advance )
  {
    PLongMetrics  longs_m;

    UShort  k = header->number_Of_HMetrics;


    if ( index < k )
    {
      longs_m = (PLongMetrics)header->long_metrics + index;
      *bearing = longs_m->bearing;
      *advance = longs_m->advance;
    }
    else
    {
      *bearing = ((PShortMetrics)header->short_metrics)[index - k];
      *advance = ((PLongMetrics)header->long_metrics)[k - 1].advance;
    }
  }


/********************************************************/
/* Return horizontal metrics in font units for a given  */
/* glyph.  If `check' is true, take care of mono-spaced */
/* fonts by returning the advance width max.            */

  static void Get_HMetrics( PFace    face,
                            UShort   index,
                            Bool     check,
                            Short*   lsb,
                            UShort*  aw )
  {
    TT_Get_Metrics( &face->horizontalHeader, index, lsb, aw );

    if ( check && face->postscript.isFixedPitch )
      *aw = face->horizontalHeader.advance_Width_Max;
  }


/********************************************************/
/* Return advance width table for a given pixel size    */
/* if it is found in the font's `hdmx' table (if any).  */

  static PByte  Get_Advance_Widths( PFace   face,
                                    UShort  ppem )
  {
    UShort  n;


    for ( n = 0; n < face->hdmx.num_records; n++ )
      if ( face->hdmx.records[n].ppem == ppem )
        return face->hdmx.records[n].widths;

    return NULL;
  }


/********************************************************/
/* Copy current glyph into original one.                */

#define cur_to_org( n, zone ) \
          MEM_Copy( (zone)->org, (zone)->cur, (n) * sizeof ( TT_Vector ) )

/********************************************************/
/* copy original glyph into current one                 */

#define org_to_cur( n, zone ) \
          MEM_Copy( (zone)->cur, (zone)->org, (n) * sizeof ( TT_Vector ) )

/********************************************************/
/* translate an array of coordinates                    */

  static void  translate_array( UShort     n,
                                TT_Vector* coords,
                                TT_Pos     delta_x,
                                TT_Pos     delta_y )
  {
    UShort  k;


    if ( delta_x )
      for ( k = 0; k < n; k++ )
        coords[k].x += delta_x;

    if ( delta_y )
      for ( k = 0; k < n; k++ )
        coords[k].y += delta_y;
  }


/********************************************************/
/* mount one zone on top of another                     */

  static void  mount_zone( PGlyph_Zone  source,
                           PGlyph_Zone  target )
  {
    UShort  np;
    Short   nc;

    np = source->n_points;
    nc = source->n_contours;

    target->org   = source->org + np;
    target->cur   = source->cur + np;
    target->touch = source->touch + np;

    target->contours = source->contours + nc;

    target->n_points   = 0;
    target->n_contours = 0;
  }


/*******************************************************************
 *
 *  Function:  Load_Simple_Glyph
 *
 ******************************************************************/

  static TT_Error  Load_Simple_Glyph( PExecution_Context  exec,
                                      TT_Stream           input,
                                      Short               n_contours,
                                      Short               left_contours,
                                      UShort              left_points,
                                      UShort              load_flags,
                                      PSubglyph_Record    subg )
  {
    DEFINE_LOAD_LOCALS( input );

    PGlyph_Zone  pts;
    Short        k;
    UShort       j;
    UShort       n_points, n_ins;
    PFace        face;
    Byte*        flag;
    TT_Vector*   vec;
    TT_F26Dot6   x, y;


    face = exec->face;

    /* simple check */
    if ( n_contours > left_contours )
      return TT_Err_Too_Many_Contours;


    /* preparing the execution context */
    mount_zone( &subg->zone, &exec->pts );

    /* reading the contours endpoints */
    if ( ACCESS_Frame( (n_contours + 1) * 2L ) )
      return error;

    for ( k = 0; k < n_contours; k++ )
      exec->pts.contours[k] = GET_UShort();


    if ( n_contours > 0 )
      n_points = exec->pts.contours[n_contours - 1] + 1;
    else
      n_points = 0;

    n_ins = GET_UShort();

    FORGET_Frame();

    if ( n_points > left_points )
      return TT_Err_Too_Many_Points;

    /* loading instructions */

    if ( n_ins > face->maxProfile.maxSizeOfInstructions )
      return TT_Err_Too_Many_Ins;

    if ( FILE_Read( exec->glyphIns, n_ins ) )
      return error;

    if ( (error = Set_CodeRange( exec,
                                 TT_CodeRange_Glyph,
                                 exec->glyphIns,
                                 n_ins )) != TT_Err_Ok )
      return error;


    /* read the flags */

    if ( CHECK_ACCESS_Frame( n_points * 5L ) )
      return error;

    j    = 0;
    flag = exec->pts.touch;

    while ( j < n_points )
    {
      Byte  c, cnt;

      flag[j] = c = GET_Byte();
      j++;

      if ( c & 8 )
      {
        cnt = GET_Byte();
        while( cnt > 0 )
        {
          flag[j++] = c;
          cnt--;
        }
      }
    }

    /* read the X */

    x    = 0;
    vec  = exec->pts.org;

    for ( j = 0; j < n_points; j++ )
    {
      if ( flag[j] & 2 )
      {
        if ( flag[j] & 16 )
          x += GET_Byte();
        else
          x -= GET_Byte();
      }
      else
      {
        if ( (flag[j] & 16) == 0 )
          x += GET_Short();
      }

      vec[j].x = x;
    }


   /* read the Y */

    y    = 0;

    for ( j = 0; j < n_points; j++ )
    {
      if ( flag[j] & 4 )
      {
        if ( flag[j] & 32 )
          y += GET_Byte();
        else
          y -= GET_Byte();
      }
      else
      {
        if ( (flag[j] & 32) == 0 )
          y += GET_Short();
      }

      vec[j].y = y;
    }

    FORGET_Frame();

    /* Now add the two shadow points at n and n + 1.    */
    /* We need the left side bearing and advance width. */

    /* pp1 = xMin - lsb */
    vec[n_points].x = subg->metrics.bbox.xMin - subg->metrics.horiBearingX;
    vec[n_points].y = 0;

    /* pp2 = pp1 + aw */
    vec[n_points+1].x = vec[n_points].x + subg->metrics.horiAdvance;
    vec[n_points+1].y = 0;

    /* clear the touch flags */

    for ( j = 0; j < n_points; j++ )
      exec->pts.touch[j] &= TT_Flag_On_Curve;

    exec->pts.touch[n_points    ] = 0;
    exec->pts.touch[n_points + 1] = 0;

    /* Note that we return two more points that are not */
    /* part of the glyph outline.                       */

    n_points += 2;

    /* now eventually scale and hint the glyph */

    pts = &exec->pts;
    pts->n_points   = n_points;
    pts->n_contours = n_contours;

    if ( (load_flags & TTLOAD_SCALE_GLYPH) == 0 )
    {
      /* no scaling, just copy the orig arrays into the cur ones */
      org_to_cur( n_points, pts );
    }
    else
    {
     /* first scale the glyph points */

      for ( j = 0; j < n_points; j++ )
      {
        pts->org[j].x = Scale_X( &exec->metrics, pts->org[j].x );
        pts->org[j].y = Scale_Y( &exec->metrics, pts->org[j].y );
      }

      /* if hinting, round pp1, and shift the glyph accordingly */
      if ( subg->is_hinted )
      {
        x = pts->org[n_points - 2].x;
        x = ((x+32) & -64) - x;
        translate_array( n_points, pts->org, x, 0 );

        org_to_cur( n_points, pts );

        pts->cur[n_points - 1].x = (pts->cur[n_points - 1].x + 32) & -64;

        /* now consider hinting */
        if ( n_ins > 0 )
        {
          exec->is_composite     = FALSE;
          exec->pedantic_hinting = load_flags & TTLOAD_PEDANTIC;

          error = Context_Run( exec, FALSE );
          if (error && exec->pedantic_hinting)
            return error;
        }
      }
      else
        org_to_cur( n_points, pts );
    }

    /* save glyph phantom points */
    if (!subg->preserve_pps)
    {
      subg->pp1 = pts->cur[n_points - 2];
      subg->pp2 = pts->cur[n_points - 1];
    }

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Load_Composite_End
 *
 ******************************************************************/

  static
  TT_Error  Load_Composite_End( UShort              n_points,
                                Short               n_contours,
                                PExecution_Context  exec,
                                PSubglyph_Record    subg,
                                UShort              load_flags,
                                TT_Stream           input )
  {
    DEFINE_LOAD_LOCALS( input );

    UShort       k, n_ins;
    PGlyph_Zone  pts;


    if ( subg->is_hinted                    &&
         subg->element_flag & WE_HAVE_INSTR )
    {
      if ( ACCESS_Frame( 2L ) )
        return error;

      n_ins = GET_UShort();     /* read size of instructions */
      FORGET_Frame();

      if ( n_ins > exec->face->maxProfile.maxSizeOfInstructions )
        return TT_Err_Too_Many_Ins;

      if ( FILE_Read( exec->glyphIns, n_ins ) )
        return error;

      error = Set_CodeRange( exec,
                             TT_CodeRange_Glyph,
                             exec->glyphIns,
                             n_ins );

      if ( error )
        return error;
    }
    else
      n_ins = 0;


    /* prepare the execution context */
    n_points += 2;
    exec->pts = subg->zone;
    pts       = &exec->pts;

    pts->n_points   = n_points;
    pts->n_contours = n_contours;

    /* add phantom points */
    pts->cur[n_points - 2] = subg->pp1;
    pts->cur[n_points - 1] = subg->pp2;

    pts->touch[n_points - 1] = 0;
    pts->touch[n_points - 2] = 0;

    /* if hinting, round the phantom points */
    if ( subg->is_hinted )
    {
      pts->cur[n_points - 2].x = (subg->pp1.x + 32) & -64;
      pts->cur[n_points - 1].x = (subg->pp2.x + 32) & -64;
    }

    for ( k = 0; k < n_points; k++ )
      pts->touch[k] &= TT_Flag_On_Curve;

    cur_to_org( n_points, pts );

    /* now consider hinting */
    if ( subg->is_hinted && n_ins > 0 )
    {
      exec->is_composite     = TRUE;
      exec->pedantic_hinting = load_flags & TTLOAD_PEDANTIC;

      error = Context_Run( exec, FALSE );
      if (error && exec->pedantic_hinting)
        return error;
    }

    /* save glyph origin and advance points */
    subg->pp1 = pts->cur[n_points - 2];
    subg->pp2 = pts->cur[n_points - 1];

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Init_Glyph_Component
 *
 ******************************************************************/

  static
  void  Init_Glyph_Component( PSubglyph_Record    element,
                              PSubglyph_Record    original,
                              PExecution_Context  exec )
  {
    element->index     = -1;
    element->is_scaled = FALSE;
    element->is_hinted = FALSE;

    if ( original )
      mount_zone( &original->zone, &element->zone );
    else
      element->zone = exec->pts;

    element->zone.n_contours = 0;
    element->zone.n_points   = 0;

    element->arg1 = 0;
    element->arg2 = 0;

    element->element_flag = 0;
    element->preserve_pps = FALSE;

    element->transform.xx = 1L << 16;
    element->transform.xy = 0;
    element->transform.yx = 0;
    element->transform.yy = 1L << 16;

    element->transform.ox = 0;
    element->transform.oy = 0;

    element->metrics.horiBearingX = 0;
    element->metrics.horiAdvance  = 0;
  }



  LOCAL_FUNC
  TT_Error  Load_TrueType_Glyph(  PInstance   instance,
                                  PGlyph      glyph,
                                  UShort      glyph_index,
                                  UShort      load_flags )
  {
    enum TPhases_
    {
      Load_Exit,
      Load_Glyph,
      Load_Header,
      Load_Simple,
      Load_Composite,
      Load_End
    };

    typedef enum TPhases_  TPhases;

    DEFINE_ALL_LOCALS;

    PFace   face;

    UShort  num_points;
    Short   num_contours;
    UShort  left_points;
    Short   left_contours;
    UShort  num_elem_points;

    Long    table;
    UShort  load_top;
    Long    k, l;
    UShort  new_flags;
    Short   index;
    UShort  u, v;

    Long  glyph_offset, offset;

    TT_F26Dot6  x, y, nx, ny;

    Fixed  xx, xy, yx, yy;

    PExecution_Context  exec;

    PSubglyph_Record  subglyph, subglyph2;

    TGlyph_Zone base_pts;

    TPhases     phase;
    PByte       widths;


    /* first of all, check arguments */
    if ( !glyph )
      return TT_Err_Invalid_Glyph_Handle;

    face = glyph->face;
    if ( !face )
      return TT_Err_Invalid_Glyph_Handle;

    if ( glyph_index >= face->numGlyphs )
      return TT_Err_Invalid_Glyph_Index;

    if ( instance && (load_flags & TTLOAD_SCALE_GLYPH) == 0 )
    {
      instance    = 0;
      load_flags &= ~( TTLOAD_SCALE_GLYPH | TTLOAD_HINT_GLYPH );
    }

    table = TT_LookUp_Table( face, TTAG_glyf );
    if ( table < 0 )
      return TT_Err_Glyf_Table_Missing;

    glyph_offset = face->dirTables[table].Offset;

    /* query new execution context */

    if ( instance && instance->debug )
      exec = instance->context;
    else
      exec = New_Context( face );

    if ( !exec )
      return TT_Err_Could_Not_Find_Context;

    Context_Load( exec, face, instance );

    if ( instance )
    {
      if ( instance->GS.instruct_control & 2 )
        exec->GS = Default_GraphicsState;
      else
        exec->GS = instance->GS;
      /* load default graphics state */

      glyph->outline.high_precision = ( instance->metrics.y_ppem < 24 );
    }

    /* save its critical pointers, as they'll be modified during load */
    base_pts = exec->pts;

    /* init variables */
    left_points   = face->maxPoints;
    left_contours = face->maxContours;

    num_points   = 0;
    num_contours = 0;

    load_top = 0;
    subglyph = exec->loadStack;

    Init_Glyph_Component( subglyph, NULL, exec );

    subglyph->index     = glyph_index;
    subglyph->is_hinted = load_flags & TTLOAD_HINT_GLYPH;

    /* when the cvt program has disabled hinting, the argument */
    /* is ignored.                                             */
    if ( instance && instance->GS.instruct_control & 1 )
      subglyph->is_hinted = FALSE;


    /* now access stream */

    if ( USE_Stream( face->stream, stream ) )
      goto Fin;

    /* Main loading loop */

    phase = Load_Glyph;
    index = 0;

    while ( phase != Load_Exit )
    {
      subglyph = exec->loadStack + load_top;

      switch ( phase )
      {
        /************************************************************/
        /*                                                          */
        /* Load_Glyph state                                         */
        /*                                                          */
        /*   reading a glyph's generic header to determine          */
        /*   whether it's simple or composite                       */
        /*                                                          */
        /* exit states: Load_Header and Load_End                    */

      case Load_Glyph:
        /* check glyph index and table */

        index = subglyph->index;
        if ( index < 0 || index >= face->numGlyphs )
        {
          error = TT_Err_Invalid_Glyph_Index;
          goto Fail;
        }

        /* get horizontal metrics */

        {
          Short   left_bearing;
          UShort  advance_width;


          Get_HMetrics( face, index,
                        !(load_flags & TTLOAD_IGNORE_GLOBAL_ADVANCE_WIDTH),
                        &left_bearing,
                        &advance_width );

          subglyph->metrics.horiBearingX = left_bearing;
          subglyph->metrics.horiAdvance  = advance_width;
        }

        phase = Load_Header;

        break;


        /************************************************************/
        /*                                                          */
        /* Load_Header state                                        */
        /*                                                          */
        /*   reading a glyph's generic header to determine          */
        /*   wether it's simple or composite                        */
        /*                                                          */
        /* exit states: Load_Simple and Load_Composite              */
        /*                                                          */

      case Load_Header: /* load glyph */

        if ( index + 1 < face->numLocations &&
             face->glyphLocations[index] == face->glyphLocations[index + 1] )
        {
          /* as described by Frederic Loyer, these are spaces, and */
          /* not the unknown glyph.                                */

          num_contours = 0;
          num_points   = 0;

          subglyph->metrics.bbox.xMin = 0;
          subglyph->metrics.bbox.xMax = 0;
          subglyph->metrics.bbox.yMin = 0;
          subglyph->metrics.bbox.yMax = 0;

          subglyph->pp1.x = 0;
          subglyph->pp2.x = subglyph->metrics.horiAdvance;
          if (load_flags & TTLOAD_SCALE_GLYPH)
            subglyph->pp2.x = Scale_X( &exec->metrics, subglyph->pp2.x );

          exec->glyphSize = 0;
          phase = Load_End;
          break;
        }

        offset = glyph_offset + face->glyphLocations[index];

        /* read first glyph header */
        if ( FILE_Seek( offset ) ||
             ACCESS_Frame( 10L ) )
          goto Fail_File;

        num_contours = GET_Short();

        subglyph->metrics.bbox.xMin = GET_Short();
        subglyph->metrics.bbox.yMin = GET_Short();
        subglyph->metrics.bbox.xMax = GET_Short();
        subglyph->metrics.bbox.yMax = GET_Short();

        FORGET_Frame();

        if ( num_contours > left_contours )
        {
          error = TT_Err_Too_Many_Contours;
          goto Fail;
        }

        subglyph->pp1.x = subglyph->metrics.bbox.xMin -
                          subglyph->metrics.horiBearingX;
        subglyph->pp1.y = 0;
        subglyph->pp2.x = subglyph->pp1.x + subglyph->metrics.horiAdvance;
        if (load_flags & TTLOAD_SCALE_GLYPH)
        {
          subglyph->pp1.x = Scale_X( &exec->metrics, subglyph->pp1.x );
          subglyph->pp2.x = Scale_X( &exec->metrics, subglyph->pp2.x );
        }

        /* is it a simple glyph ? */
        if ( num_contours > 0 )
          phase = Load_Simple;
        else
          phase = Load_Composite;

        break;


        /************************************************************/
        /*                                                          */
        /* Load_Simple state                                        */
        /*                                                          */
        /*   reading a simple glyph (num_contours must be set to    */
        /*   the glyph's number of contours.)                       */
        /*                                                          */
        /* exit states : Load_End                                   */
        /*                                                          */

      case Load_Simple:
        new_flags = load_flags;

        /* disable hinting when scaling */
        if ( !subglyph->is_hinted )
          new_flags &= ~TTLOAD_HINT_GLYPH;

        error = Load_Simple_Glyph( exec,
                                   stream,
                                   num_contours,
                                   left_contours,
                                   left_points,
                                   new_flags,
                                   subglyph );
        if ( error )
          goto Fail;

        /* Note: We could have put the simple loader source there */
        /*       but the code is fat enough already :-)           */

        num_points = exec->pts.n_points - 2;

        phase = Load_End;

        break;


        /************************************************************/
        /*                                                          */
        /* Load_Composite state                                     */
        /*                                                          */
        /*   reading a composite glyph header a pushing a new       */
        /*   load element on the stack.                             */
        /*                                                          */
        /* exit states: Load_Glyph                                  */
        /*                                                          */

      case Load_Composite:

        /* create a new element on the stack */
        load_top++;

        if ( load_top > face->maxComponents )
        {
          error = TT_Err_Invalid_Composite;
          goto Fail;
        }

        subglyph2 = exec->loadStack + load_top;

        Init_Glyph_Component( subglyph2, subglyph, NULL );
        subglyph2->is_hinted = subglyph->is_hinted;

        /* now read composite header */

        if ( ACCESS_Frame( 4L ) )
          goto Fail_File;

        subglyph->element_flag = new_flags = GET_UShort();

        subglyph2->index = GET_UShort();

        FORGET_Frame();

        k = 1 + 1;

        if ( new_flags & ARGS_ARE_WORDS )
          k *= 2;

        if ( new_flags & WE_HAVE_A_SCALE )
          k += 2;

        else if ( new_flags & WE_HAVE_AN_XY_SCALE )
          k += 4;

        else if ( new_flags & WE_HAVE_A_2X2 )
          k += 8;

        if ( ACCESS_Frame( k ) )
          goto Fail_File;

        if ( new_flags & ARGS_ARE_WORDS )
        {
          k = GET_Short();
          l = GET_Short();
        }
        else
        {
          k = GET_Char();
          l = GET_Char();
        }

        subglyph->arg1 = k;
        subglyph->arg2 = l;

        if ( new_flags & ARGS_ARE_XY_VALUES )
        {
          subglyph->transform.ox = k;
          subglyph->transform.oy = l;
        }

        xx = 1L << 16;
        xy = 0;
        yx = 0;
        yy = 1L << 16;

        if ( new_flags & WE_HAVE_A_SCALE )
        {
          xx = (Fixed)GET_Short() << 2;
          yy = xx;
          subglyph2->is_scaled = TRUE;
        }
        else if ( new_flags & WE_HAVE_AN_XY_SCALE )
        {
          xx = (Fixed)GET_Short() << 2;
          yy = (Fixed)GET_Short() << 2;
          subglyph2->is_scaled = TRUE;
        }
        else if ( new_flags & WE_HAVE_A_2X2 )
        {
          xx = (Fixed)GET_Short() << 2;
          xy = (Fixed)GET_Short() << 2;
          yx = (Fixed)GET_Short() << 2;
          yy = (Fixed)GET_Short() << 2;
          subglyph2->is_scaled = TRUE;
        }

        FORGET_Frame();

        subglyph->transform.xx = xx;
        subglyph->transform.xy = xy;
        subglyph->transform.yx = yx;
        subglyph->transform.yy = yy;

        k = TT_MulFix( xx, yy ) -  TT_MulFix( xy, yx );

        /* disable hinting in case of scaling/slanting */
        if ( ABS( k ) != (1L << 16) )
          subglyph2->is_hinted = FALSE;

        subglyph->file_offset = FILE_Pos();

        phase = Load_Glyph;

        break;


        /************************************************************/
        /*                                                          */
        /* Load_End state                                           */
        /*                                                          */
        /*   after loading a glyph, apply transformation and offset */
        /*   where necessary, pops element and continue or          */
        /*   stop process.                                          */
        /*                                                          */
        /* exit states : Load_Composite and Load_Exit               */
        /*                                                          */

      case Load_End:
        if ( load_top > 0 )
        {
          subglyph2 = subglyph;

          load_top--;
          subglyph = exec->loadStack + load_top;

          /* check advance width and left side bearing */

          if ( !subglyph->preserve_pps &&
               subglyph->element_flag & USE_MY_METRICS )
          {
            subglyph->metrics.horiBearingX = subglyph2->metrics.horiBearingX;
            subglyph->metrics.horiAdvance  = subglyph2->metrics.horiAdvance;

            subglyph->pp1 = subglyph2->pp1;
            subglyph->pp2 = subglyph2->pp2;

            subglyph->preserve_pps = TRUE;
          }

          /* apply scale */

          if ( subglyph2->is_scaled )
          {
            TT_Vector*  cur = subglyph2->zone.cur;
            TT_Vector*  org = subglyph2->zone.org;

            for ( u = 0; u < num_points; u++ )
            {
              nx = TT_MulFix( cur->x, subglyph->transform.xx ) +
                   TT_MulFix( cur->y, subglyph->transform.yx );

              ny = TT_MulFix( cur->x, subglyph->transform.xy ) +
                   TT_MulFix( cur->y, subglyph->transform.yy );

              cur->x = nx;
              cur->y = ny;

              nx = TT_MulFix( org->x, subglyph->transform.xx ) +
                   TT_MulFix( org->y, subglyph->transform.yx );

              ny = TT_MulFix( org->x, subglyph->transform.xy ) +
                   TT_MulFix( org->y, subglyph->transform.yy );

              org->x = nx;
              org->y = ny;

              cur++;
              org++;
            }
          }

          /* adjust counts */

          num_elem_points = subglyph->zone.n_points;

          for ( k = 0; k < num_contours; k++ )
            subglyph2->zone.contours[k] += num_elem_points;

          subglyph->zone.n_points   += num_points;
          subglyph->zone.n_contours += num_contours;

          left_points   -= num_points;
          left_contours -= num_contours;

          if ( !(subglyph->element_flag & ARGS_ARE_XY_VALUES) )
          {
            /* move second glyph according to control points */
            /* the attach points are relative to the specific component */

            u = (UShort)subglyph->arg1;
            v = (UShort)subglyph->arg2;

            if ( u >= num_elem_points ||
                 v >= num_points )
            {
              error = TT_Err_Invalid_Composite;
              goto Fail;
            }

            /* adjust count */
            v += num_elem_points;

            x = subglyph->zone.cur[u].x - subglyph->zone.cur[v].x;
            y = subglyph->zone.cur[u].y - subglyph->zone.cur[v].y;
          }
          else
          {
            /* apply offset */

            x = subglyph->transform.ox;
            y = subglyph->transform.oy;

            if ( load_flags & TTLOAD_SCALE_GLYPH )
            {
              x = Scale_X( &exec->metrics, x );
              y = Scale_Y( &exec->metrics, y );

              if ( subglyph->element_flag & ROUND_XY_TO_GRID )
              {
                x = (x+32) & -64;
                y = (y+32) & -64;
              }
            }
          }

          translate_array( num_points, subglyph2->zone.cur, x, y );

          cur_to_org( num_points, &subglyph2->zone );

          num_points   = subglyph->zone.n_points;
          num_contours = subglyph->zone.n_contours;

          /* check for last component */

          if ( FILE_Seek( subglyph->file_offset ) )
            goto Fail_File;

          if ( subglyph->element_flag & MORE_COMPONENTS )
            phase = Load_Composite;
          else
          {
            error = Load_Composite_End( num_points,
                                        num_contours,
                                        exec,
                                        subglyph,
                                        load_flags,
                                        stream );
            if ( error )
              goto Fail;

            phase = Load_End;
          }
        }
        else
          phase = Load_Exit;

        break;


      case Load_Exit:
        break;
      }
    }

    /* finally, copy the points arrays to the glyph object */

    exec->pts = base_pts;

    for ( u = 0; u < num_points + 2; u++ )
    {
      glyph->outline.points[u] = exec->pts.cur[u];
      glyph->outline.flags [u] = exec->pts.touch[u];
    }

    for ( k = 0; k < num_contours; k++ )
      glyph->outline.contours[k] = exec->pts.contours[k];

    glyph->outline.n_points    = num_points;
    glyph->outline.n_contours  = num_contours;
    glyph->outline.second_pass = TRUE;

    /* translate array so that (0,0) is the glyph's origin */
    translate_array( num_points + 2,
                     glyph->outline.points,
                     -subglyph->pp1.x,
                     0 );

    TT_Get_Outline_BBox( &glyph->outline, &glyph->metrics.bbox );

    if ( subglyph->is_hinted )
    {
      /* grid-fit the bounding box */
      glyph->metrics.bbox.xMin &= -64;
      glyph->metrics.bbox.yMin &= -64;
      glyph->metrics.bbox.xMax  = (glyph->metrics.bbox.xMax+63) & -64;
      glyph->metrics.bbox.yMax  = (glyph->metrics.bbox.yMax+63) & -64;
    }

    /* get the device-independent scaled horizontal metrics */
    /* take care of fixed-pitch fonts...                    */
    {
      TT_Pos  left_bearing;
      TT_Pos  advance;


      left_bearing = subglyph->metrics.horiBearingX;
      advance      = subglyph->metrics.horiAdvance;

      if ( face->postscript.isFixedPitch )
        advance = face->horizontalHeader.advance_Width_Max;

      if ( load_flags & TTLOAD_SCALE_GLYPH )
      {
        left_bearing = Scale_X( &exec->metrics, left_bearing );
        advance      = Scale_X( &exec->metrics, advance      );
      }

      glyph->metrics.linearHoriBearingX = left_bearing;
      glyph->metrics.linearHoriAdvance  = advance;
    }

    glyph->metrics.horiBearingX = glyph->metrics.bbox.xMin;
    glyph->metrics.horiBearingY = glyph->metrics.bbox.yMax;
    glyph->metrics.horiAdvance  = subglyph->pp2.x - subglyph->pp1.x;

    /* Now take care of vertical metrics.  In the case where there is    */
    /* no vertical information within the font (relatively common), make */
    /* up some metrics `by hand' ...                                     */

    {
      Short   top_bearing;    /* vertical top side bearing (EM units) */
      UShort  advance_height; /* vertical advance height (EM units)   */

      TT_Pos  left;     /* scaled vertical left side bearing          */
      TT_Pos  Top;      /* scaled original vertical top side bearing  */
      TT_Pos  top;      /* scaled vertical top side bearing           */
      TT_Pos  advance;  /* scaled vertical advance height             */


      /* Get the unscaled `tsb' and `ah' values */
      if ( face->verticalInfo                          &&
           face->verticalHeader.number_Of_VMetrics > 0 )
      {
        /* Don't assume that both the vertical header and vertical */
        /* metrics are present in the same font :-)                */

        TT_Get_Metrics( (TT_Horizontal_Header*)&face->verticalHeader,
                        glyph_index,
                        &top_bearing,
                        &advance_height );
      }
      else
      {
        /* Make up the distances from the horizontal header..     */

        /* NOTE: The OS/2 values are the only `portable' ones,    */
        /*       which is why we use them...                      */
        /*                                                        */
        /* NOTE2: The sTypoDescender is negative, which is why    */
        /*        we compute the baseline-to-baseline distance    */
        /*        here with :                                     */
        /*             ascender - descender + linegap             */
        /*                                                        */
        top_bearing    = (Short) (face->os2.sTypoLineGap / 2);
        advance_height = (UShort)(face->os2.sTypoAscender -
                                  face->os2.sTypoDescender +
                                  face->os2.sTypoLineGap);
      }

      /* We must adjust the top_bearing value from the bounding box given
         in the glyph header to te bounding box calculated with
         TT_Get_Outline_BBox()                                            */

      /* scale the metrics */
      if ( load_flags & TTLOAD_SCALE_GLYPH )
      {
        Top     = Scale_Y( &exec->metrics, top_bearing );
        top     = Scale_Y( &exec->metrics,
                           top_bearing + subglyph->metrics.bbox.yMax ) -
                    glyph->metrics.bbox.yMax;
        advance = Scale_Y( &exec->metrics, advance_height );
      }
      else
      {
        Top     = top_bearing;
        top     = top_bearing + subglyph->metrics.bbox.yMax -
                    glyph->metrics.bbox.yMax;
        advance = advance_height;
      }

      glyph->metrics.linearVertBearingY = Top;
      glyph->metrics.linearVertAdvance  = advance;

      /* XXX : for now, we have no better algo for the lsb, but it should */
      /*       work ok..                                                  */
      /*                                                                  */
      left = ( glyph->metrics.bbox.xMin - glyph->metrics.bbox.xMax ) / 2;

      /* grid-fit them if necessary */
      if ( subglyph->is_hinted )
      {
        left   &= -64;
        top     = (top + 63) & -64;
        advance = (advance + 32) & -64;
      }

      glyph->metrics.vertBearingX = left;
      glyph->metrics.vertBearingY = top;
      glyph->metrics.vertAdvance  = advance;
    }

    /* Adjust advance width to the value contained in the hdmx table. */
    if ( !exec->face->postscript.isFixedPitch && instance &&
         subglyph->is_hinted )
    {
      widths = Get_Advance_Widths( exec->face,
                                   exec->instance->metrics.x_ppem );
      if ( widths )
        glyph->metrics.horiAdvance = widths[glyph_index] << 6;
    }

    glyph->outline.dropout_mode = (Char)exec->GS.scan_type;

    error = TT_Err_Ok;

  Fail_File:
  Fail:
    DONE_Stream( stream );

  Fin:

    /* reset the execution context */
    exec->pts = base_pts;

    if ( !instance || !instance->debug )
      Done_Context( exec );

    return error;
  }


/* END */
