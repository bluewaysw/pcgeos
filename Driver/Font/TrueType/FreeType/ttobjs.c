/*******************************************************************
 *
 *  ttobjs.c                                                     1.0
 *
 *    Objects manager.
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

#include "ttobjs.h"
#include "ttfile.h"
#include "ttcalc.h"
#include "ttmemory.h"
#include "ttload.h"
#include "ttinterp.h"


/* Add extensions definition */
#ifdef TT_CONFIG_OPTION_EXTEND_ENGINE
#include "ttextend.h"
#endif


#ifdef __GEOS__
extern TEngine_Instance engineInstance;
#endif  /* __GEOS__ */


/* Required by tracing mode */
#undef   TT_COMPONENT
#define  TT_COMPONENT  trace_objs

/*******************************************************************
 *
 *  Function    :  New_Context
 *
 *  Description :  Creates a new execution context for a given
 *                 face object.
 *
 ******************************************************************/

  LOCAL_FUNC
  PExecution_Context  New_Context( PFace  face )
  {
    PExecution_Context  exec;


    if ( !face )
      return NULL;

    CACHE_New( engineInstance.objs_exec_cache, exec, face );
    return exec;
  }


/*******************************************************************
 *
 *  Function    :  Done_Context
 *
 *  Description :  Discards an execution context.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Done_Context( PExecution_Context  exec )
  {
    if ( !exec )
      return TT_Err_Ok;

    return CACHE_Done( engineInstance.objs_exec_cache, exec );
  }


/*******************************************************************
 *                                                                 *
 *                     GLYPH ZONE FUNCTIONS                        *
 *                                                                 *
 *                                                                 *
 *******************************************************************/

/*******************************************************************
 *
 *  Function    :  New_Glyph_Zone
 *
 *  Description :  Allocates a new glyph zone
 *
 *  Input  :  pts          pointer to the target glyph zone record
 *            maxPoints    capacity of glyph zone in points
 *            maxContours  capacity of glyph zone in contours
 *
 *  Return :  Error code.
 *
 *****************************************************************/

  static
  TT_Error  New_Glyph_Zone( PGlyph_Zone  pts,
                            UShort       maxPoints,
                            UShort       maxContours )
  {
    TT_Error  error;


    if ( ALLOC( pts->org, maxPoints * 2 * sizeof ( TT_F26Dot6 ) ) ||
         ALLOC( pts->cur, maxPoints * 2 * sizeof ( TT_F26Dot6 ) ) ||
         ALLOC( pts->touch, maxPoints * sizeof ( Byte )         ) ||
         ALLOC( pts->contours, maxContours * sizeof ( Short ) ) )
      return error;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Done_Glyph_Zone
 *
 *  Description :  Deallocates a glyph zone
 *
 *  Input  :  pts          pointer to the target glyph zone record
 *
 *  Return :  Error code.
 *
 *****************************************************************/

  static
  TT_Error  Done_Glyph_Zone( PGlyph_Zone  pts )
  {
    FREE( pts->contours );
    FREE( pts->touch );
    FREE( pts->cur );
    FREE( pts->org );

    return TT_Err_Ok;
  }



/*******************************************************************
 *                                                                 *
 *                     CODERANGE FUNCTIONS                         *
 *                                                                 *
 *******************************************************************/

/*******************************************************************
 *
 *  Function    :  Goto_CodeRange
 *
 *  Description :  Switch to a new code range (updates Code and IP).
 *
 *  Input  :  exec    target execution context
 *            range   new execution code range
 *            IP      new IP in new code range
 *
 *  Output :  SUCCESS on success.  FAILURE on error (no code range).
 *
 *****************************************************************/

  LOCAL_FUNC
  TT_Error  Goto_CodeRange( PExecution_Context  exec,
                            Int                 range,
                            UShort              IP )
  {
    PCodeRange  cr;


    if ( range < 1 || range > 3 )
      return TT_Err_Bad_Argument;

    cr = &exec->codeRangeTable[range - 1];

    if ( cr->Base == NULL )
      return TT_Err_Invalid_CodeRange;

    /* NOTE:  Because the last instruction of a program may be a CALL */
    /*        which will return to the first byte *after* the code    */
    /*        range, we test for IP <= Size, instead of IP < Size.    */

    if ( IP > cr->Size )
      return TT_Err_Code_Overflow;

    exec->code     = cr->Base;
    exec->codeSize = cr->Size;
    exec->IP       = IP;
    exec->curRange = range;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Set_CodeRange
 *
 *  Description :  Sets a code range.
 *
 *  Input  :  exec    target execution context
 *            range   code range index
 *            base    new code base
 *            length  range size in bytes
 *
 *  Output :  SUCCESS on success.  FAILURE on error.
 *
 *****************************************************************/

  LOCAL_FUNC
  TT_Error  Set_CodeRange( PExecution_Context  exec,
                           Int                 range,
                           void*               base,
                           UShort              length )
  {
    if ( range < 1 || range > 3 )
      return TT_Err_Bad_Argument;

    exec->codeRangeTable[range - 1].Base = (Byte*)base;
    exec->codeRangeTable[range - 1].Size = length;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Clear_CodeRange
 *
 *  Description :  Clears a code range.
 *
 *  Input  :  exec    target execution context
 *            range   code range index
 *
 *  Output :  SUCCESS on success.  FAILURE on error.
 *
 *  Note   : Does not set the Error variable.
 *
 *****************************************************************/

  LOCAL_FUNC
  TT_Error Clear_CodeRange( PExecution_Context  exec, Int  range )
  {
    if ( range < 1 || range > 3 )
      return TT_Err_Bad_Argument;

    exec->codeRangeTable[range - 1].Base = NULL;
    exec->codeRangeTable[range - 1].Size = 0;

    return TT_Err_Ok;
  }



/*******************************************************************
 *                                                                 *
 *                EXECUTION CONTEXT ROUTINES                       *
 *                                                                 *
 *******************************************************************/

/*******************************************************************
 *
 *  Function    :  Context_Destroy
 *
 *****************************************************************/

  LOCAL_FUNC
  TT_Error  Context_Destroy( void*  _context )
  {
    PExecution_Context  exec = (PExecution_Context)_context;

    if ( !exec )
      return TT_Err_Ok;

    /* free composite load stack */
    FREE( exec->loadStack );
    exec->loadSize = 0;

    /* points zone */
    Done_Glyph_Zone( &exec->pts );
    exec->maxPoints   = 0;
    exec->maxContours = 0;

    /* free stack */
    FREE( exec->stack );
    exec->stackSize = 0;

    /* free call stack */
    FREE( exec->callStack );
    exec->callSize = 0;
    exec->callTop  = 0;

    /* free glyph code range */
    FREE( exec->glyphIns );
    exec->glyphSize = 0;

    exec->instance = NULL;
    exec->face     = NULL;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Context_Create
 *
 *****************************************************************/

  LOCAL_FUNC
  TT_Error  Context_Create( void*  _context, void*  _face )
  {
    PExecution_Context  exec = (PExecution_Context)_context;

    PFace        face = (PFace)_face;
    TT_Error     error;


    /* XXX : We don't reserve arrays anymore, this is done automatically */
    /*       during a "Context_Load"..                                   */

    exec->callSize  = 32;
    if ( ALLOC_ARRAY( exec->callStack, exec->callSize, TCallRecord ) )
      goto Fail_Memory;

    /* all values in the context are set to 0 already, but this is */
    /* here as a remainder                                         */
    exec->maxPoints   = 0;
    exec->maxContours = 0;

    exec->stackSize = 0;
    exec->loadSize  = 0;
    exec->glyphSize = 0;

    exec->stack     = NULL;
    exec->loadStack = NULL;
    exec->glyphIns  = NULL;

    exec->face     = face;
    exec->instance = NULL;

    return TT_Err_Ok;

  Fail_Memory:
    Context_Destroy( exec );
    return error;
  }


/*******************************************************************
 *
 *  Function    :  Context_Load
 *
 *****************************************************************/

/****************************************************************/
/*                                                              */
/* Update_Max : Reallocate a buffer if it needs to              */
/*                                                              */
/* input:  size        address of buffer's current size         */
/*                     expressed in elements                    */
/*                                                              */
/*         multiplier  size in bytes of each element in the     */
/*                     buffer                                   */
/*                                                              */
/*         buff        address of the buffer base pointer       */
/*                                                              */
/*         new_max     new capacity (size) of the buffer        */

  static
  TT_Error  Update_Max( UShort*  size,
                        UShort   multiplier,
                        void**   buff,
                        UShort   new_max )
  {
    TT_Error  error;

    if ( *size < new_max )
    {
      FREE( *buff );
      if ( ALLOC( *buff, new_max * multiplier ) )
        return error;
      *size = new_max;
    }
    return TT_Err_Ok;
  }


/****************************************************************/
/*                                                              */
/* Update_Zone: Reallocate a zone if it needs to                */
/*                                                              */
/* input:  zone        address of the target zone               */
/*                                                              */
/*         maxPoints   address of the zone's current capacity   */
/*                     in points                                */
/*                                                              */
/*         maxContours address of the zone's current capacity   */
/*                     in contours                              */
/*                                                              */
/*         newPoints   new capacity in points                   */
/*                                                              */
/*         newContours new capacity in contours                 */
/*                                                              */

  static
  TT_Error  Update_Zone( PGlyph_Zone  zone,
                         UShort*      maxPoints,
                         UShort*      maxContours,
                         UShort       newPoints,
                         UShort       newContours )
  {
    if ( *maxPoints < newPoints || *maxContours < newContours )
    {
      TT_Error  error;


      Done_Glyph_Zone( zone );

      error = New_Glyph_Zone( zone, newPoints, newContours );
      if ( error )
        return error;

      *maxPoints   = newPoints;
      *maxContours = newContours;
    }
    return TT_Err_Ok;
  }


  LOCAL_FUNC
  TT_Error Context_Load( PExecution_Context  exec,
                         PFace               face,
                         PInstance           ins )
  {
    Int           i;
    TMaxProfile*  maxp;
    TT_Error      error;

    exec->face     = face;
    maxp           = &face->maxProfile;

    exec->instance = ins;

    if ( ins )
    {
      exec->numFDefs = ins->numFDefs;
      exec->numIDefs = ins->numIDefs;
      exec->maxFDefs = ins->maxFDefs;
      exec->maxIDefs = ins->maxIDefs;
      exec->FDefs    = ins->FDefs;
      exec->IDefs    = ins->IDefs;
      exec->metrics  = ins->metrics;

      exec->maxFunc  = ins->maxFunc;
      exec->maxIns   = ins->maxIns;

      for ( i = 0; i < MAX_CODE_RANGES; ++i )
        exec->codeRangeTable[i] = ins->codeRangeTable[i];

      /* set graphics state */
      exec->GS = ins->GS;

      exec->cvtSize = ins->cvtSize;
      exec->cvt     = ins->cvt;

      exec->storeSize = ins->storeSize;
      exec->storage   = ins->storage;

      exec->twilight  = ins->twilight;
    }

    error = Update_Max( &exec->loadSize,
                        sizeof ( TSubglyph_Record ),
                        (void**)&exec->loadStack,
                        face->maxComponents + 1 );
    if ( error )
      return error;

    error = Update_Max( &exec->stackSize,
                        sizeof ( TT_F26Dot6 ),
                        (void**)&exec->stack,
                        maxp->maxStackElements + 32 );
    /* XXX : We reserve a little more elements on the stack to deal safely */
    /*       with broken fonts like arialbs, courbs, timesbs...            */
    if ( error )
      return error;

    error = Update_Max( &exec->glyphSize,
                        sizeof ( Byte ),
                        (void**)&exec->glyphIns,
                        maxp->maxSizeOfInstructions );
    if ( error )
      return error;

    error = Update_Zone( &exec->pts,
                         &exec->maxPoints,
                         &exec->maxContours,
                         exec->face->maxPoints + 2,
                         exec->face->maxContours );
    /* XXX : We reserve two positions for the phantom points! */
    if ( error )
      return error;

    exec->pts.n_points   = 0;
    exec->pts.n_contours = 0;

    exec->instruction_trap = FALSE;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Context_Save
 *
 *****************************************************************/

  LOCAL_FUNC
  TT_Error  Context_Save( PExecution_Context  exec,
                          PInstance           ins )
  {
    Int  i;

    /* XXXX : Will probably disappear soon with all the coderange */
    /*        management, which is now rather obsolete.           */

    ins->numFDefs = exec->numFDefs;
    ins->numIDefs = exec->numIDefs;
    ins->maxFunc  = exec->maxFunc;
    ins->maxIns   = exec->maxIns;

    for ( i = 0; i < MAX_CODE_RANGES; ++i )
      ins->codeRangeTable[i] = exec->codeRangeTable[i];

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Context_Run
 *
 *****************************************************************/

  LOCAL_FUNC
  TT_Error  Context_Run( PExecution_Context  exec )
  {
    TT_Error  error;


    if ( (error = Goto_CodeRange( exec,
                                  TT_CodeRange_Glyph, 0 )) != TT_Err_Ok )
      return error;

    exec->zp0 = exec->pts;
    exec->zp1 = exec->pts;
    exec->zp2 = exec->pts;

    exec->GS.gep0 = 1;
    exec->GS.gep1 = 1;
    exec->GS.gep2 = 1;

    exec->GS.projVector.x = 0x4000;
    exec->GS.projVector.y = 0x0000;

    exec->GS.freeVector = exec->GS.projVector;
    exec->GS.dualVector = exec->GS.projVector;

    exec->GS.round_state = 1;
    exec->GS.loop        = 1;

    /* some glyphs leave something on the stack. so we clean it */
    /* before a new execution.                                  */
    exec->top     = 0;
    exec->callTop = 0;

    return RunIns( exec );
  }


  LOCAL_FUNC
  const TGraphicsState  Default_GraphicsState =
  {
    0, 0, 0,
    { 0x4000, 0 },
    { 0x4000, 0 },
    { 0x4000, 0 },
    1, 64, 1,
    TRUE, 68, 0, 0, 9, 3,
    0, FALSE, 2, 1, 1, 1
  };



/*******************************************************************
 *                                                                 *
 *                     INSTANCE  FUNCTIONS                         *
 *                                                                 *
 *                                                                 *
 *******************************************************************/

/*******************************************************************
 *
 *  Function    : Instance_Destroy
 *
 *  Description :
 *
 *  Input  :  _instance   the instance object to destroy
 *
 *  Output :  error code.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Instance_Destroy( void* _instance )
  {
    PInstance  ins = (PInstance)_instance;


    if ( !_instance )
      return TT_Err_Ok;


    FREE( ins->cvt );
    ins->cvtSize = 0;

    /* free storage area */
    FREE( ins->storage );
    ins->storeSize = 0;

    /* twilight zone */
    Done_Glyph_Zone( &ins->twilight );

    FREE( ins->FDefs );
    FREE( ins->IDefs );
    ins->numFDefs = 0;
    ins->numIDefs = 0;
    ins->maxFDefs = 0;
    ins->maxIDefs = 0;
    ins->maxFunc  = -1;
    ins->maxIns   = -1;

    ins->owner = NULL;
    ins->valid = FALSE;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    : Instance_Create
 *
 *  Description :
 *
 *  Input  :  _instance    instance record to initialize
 *            _face        parent face object
 *
 *  Output :  Error code.  All partially built subtables are
 *            released on error.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Instance_Create( void*  _instance,
                             void*  _face )
  {
    PInstance  ins  = (PInstance)_instance;
    PFace      face = (PFace)_face;
    TT_Error   error;
    Int        i;
    UShort     n_twilight;

    PMaxProfile  maxp = &face->maxProfile;


    ins->owner = face;
    ins->valid = FALSE;

    ins->maxFDefs  = maxp->maxFunctionDefs;
    ins->maxIDefs  = maxp->maxInstructionDefs;
    ins->cvtSize   = face->cvtSize;
    ins->storeSize = maxp->maxStorage;

    /* Set default metrics */
    {
      PIns_Metrics   metrics = &ins->metrics;


      metrics->pointSize    = 10 << 6;     /* default pointsize  = 10pts */

      metrics->x_resolution = 72;          /* default resolution = 72dpi */
      metrics->y_resolution = 72;

      metrics->x_ppem = 0;
      metrics->y_ppem = 0;

      /* set default compensation ( all 0 ) */
      for ( i = 0; i < 4; ++i )
        metrics->compensations[i] = 0;
    }

    /* allocate function defs, instruction defs, cvt and storage area */
    if ( ALLOC_ARRAY( ins->FDefs,   ins->maxFDefs,  TDefRecord )  ||
         ALLOC_ARRAY( ins->IDefs,   ins->maxIDefs,  TDefRecord )  ||
         ALLOC_ARRAY( ins->cvt,     ins->cvtSize,   Long       )  ||
         ALLOC_ARRAY( ins->storage, ins->storeSize, Long       )  )
      goto Fail_Memory;

    /* reserve twilight zone */
    n_twilight = maxp->maxTwilightPoints;
    error = New_Glyph_Zone( &ins->twilight, n_twilight, 0 );
    if (error)
      goto Fail_Memory;

    ins->twilight.n_points = n_twilight;

    return TT_Err_Ok;

  Fail_Memory:
    Instance_Destroy( ins );
    return error;
  }


/*******************************************************************
 *
 *  Function    : Instance_Init
 *
 *  Description : Initialize a fresh new instance.
 *                Executes the font program if any is found.
 *
 *  Input  :  _instance   the instance object to destroy
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Instance_Init( PInstance  ins )
  {
    PExecution_Context  exec;

    TT_Error  error;
    PFace     face = ins->owner;


    exec = New_Context( face );
    /* debugging instances have their own context */

    if ( !exec )
      return TT_Err_Could_Not_Find_Context;

    ins->GS = Default_GraphicsState;

    ins->numFDefs = 0;
    ins->numIDefs = 0;
    ins->maxFunc  = -1;
    ins->maxIns   = -1;

    Context_Load( exec, face, ins );

    exec->callTop   = 0;
    exec->top       = 0;

    exec->period    = 64;
    exec->phase     = 0;
    exec->threshold = 0;

    {
      PIns_Metrics  metrics = &exec->metrics;


      metrics->x_ppem    = 0;
      metrics->y_ppem    = 0;
      metrics->pointSize = 0;
      metrics->x_scale1  = 0;
      metrics->x_scale2  = 1;
      metrics->y_scale1  = 0;
      metrics->y_scale2  = 1;

      metrics->ppem      = 0;
      metrics->scale1    = 0;
      metrics->scale2    = 1;
      metrics->ratio     = 1L << 16;
    }

    exec->instruction_trap = FALSE;

    exec->cvtSize = ins->cvtSize;
    exec->cvt     = ins->cvt;

    exec->F_dot_P = 0x10000;

    /* allow font program execution */
    Set_CodeRange( exec,
                   TT_CodeRange_Font,
                   face->fontProgram,
                   face->fontPgmSize );

    /* disable CVT and glyph programs coderange */
    Clear_CodeRange( exec, TT_CodeRange_Cvt );
    Clear_CodeRange( exec, TT_CodeRange_Glyph );

    if ( face->fontPgmSize > 0 )
    {
      error = Goto_CodeRange( exec, TT_CodeRange_Font, 0 );
      if ( error )
        goto Fin;

      error = RunIns( exec );
    }
    else
      error = TT_Err_Ok;

  Fin:
    Context_Save( exec, ins );

    Done_Context( exec );
    /* debugging instances keep their context */

    ins->valid = FALSE;

    return error;
  }


/*******************************************************************
 *
 *  Function    : Instance_Reset
 *
 *  Description : Resets an instance to a new pointsize/transform.
 *                Executes the cvt program if any is found.
 *
 *  Input  :  _instance   the instance object to destroy
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Instance_Reset( PInstance  ins )
  {
    PExecution_Context  exec;

    TT_Error  error;
    UShort    i;
    PFace     face;


    if ( !ins )
      return TT_Err_Invalid_Instance_Handle;

    if ( ins->valid )
      return TT_Err_Ok;

    face = ins->owner;

    if ( ins->metrics.x_ppem < 1 ||
         ins->metrics.y_ppem < 1 )
      return TT_Err_Invalid_PPem;

    /* compute new transformation */
    if ( ins->metrics.x_ppem >= ins->metrics.y_ppem )
    {
      ins->metrics.scale1  = ins->metrics.x_scale1;
      ins->metrics.scale2  = ins->metrics.x_scale2;
      ins->metrics.ppem    = ins->metrics.x_ppem;
      ins->metrics.x_ratio = 1L << 16;
      ins->metrics.y_ratio = TT_MulDiv( ins->metrics.y_ppem,
                                        0x10000,
                                        ins->metrics.x_ppem );
    }
    else
    {
      ins->metrics.scale1  = ins->metrics.y_scale1;
      ins->metrics.scale2  = ins->metrics.y_scale2;
      ins->metrics.ppem    = ins->metrics.y_ppem;
      ins->metrics.x_ratio = TT_MulDiv( ins->metrics.x_ppem,
                                        0x10000,
                                        ins->metrics.y_ppem );
      ins->metrics.y_ratio = 1L << 16;
    }

    /* Scale the cvt values to the new ppem.          */
    /* We use by default the y ppem to scale the CVT. */
    MulDivList( ins->cvt, ins->cvtSize, face->cvt, ins->metrics.scale1, ins->metrics.scale2 );

    /* All twilight points are originally zero */
    for ( i = 0; i < ins->twilight.n_points; ++i )
    {
      ins->twilight.org[i].x = 0;
      ins->twilight.org[i].y = 0;
      ins->twilight.cur[i].x = 0;
      ins->twilight.cur[i].y = 0;
    }

    /* clear storage area */
    for ( i = 0; i < ins->storeSize; ++i )
      ins->storage[i] = 0;

    ins->GS = Default_GraphicsState;

    /* get execution context and run prep program */

    exec = New_Context(face);
    /* debugging instances have their own context */

    if ( !exec )
      return TT_Err_Could_Not_Find_Context;

    Context_Load( exec, face, ins );

    Set_CodeRange( exec,
                   TT_CodeRange_Cvt,
                   face->cvtProgram,
                   face->cvtPgmSize );

    Clear_CodeRange( exec, TT_CodeRange_Glyph );

    exec->instruction_trap = FALSE;

    exec->top     = 0;
    exec->callTop = 0;

    if ( face->cvtPgmSize > 0 )
    {
      error = Goto_CodeRange( exec, TT_CodeRange_Cvt, 0 );
      if ( error )
        goto Fin;

      error = RunIns( exec );
    }
    else
      error = TT_Err_Ok;

    ins->GS = exec->GS;
    /* save default graphics state */

  Fin:
    Context_Save( exec, ins );

    Done_Context( exec );
    /* debugging instances keep their context */

    if ( !error )
      ins->valid = TRUE;

    return error;
  }



/*******************************************************************
 *                                                                 *
 *                         FACE  FUNCTIONS                         *
 *                                                                 *
 *                                                                 *
 *******************************************************************/

/*******************************************************************
 *
 *  Function    :  Face_Destroy
 *
 *  Description :  The face object destructor.
 *
 *  Input  :  _face   typeless pointer to the face object to destroy
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Face_Destroy( void*  _face )
  {
    PFace   face = (PFace)_face;
    UShort  n;


    if ( !face )
      return TT_Err_Ok;

    /* first of all, destroys the cached sub-objects */
    Cache_Destroy( &face->instances );
    Cache_Destroy( &face->glyphs );

    /* destroy the extensions */
#ifdef TT_CONFIG_OPTION_EXTEND_ENGINE
    Extension_Destroy( face );
#endif

    /* freeing table directory */
    FREE( face->dirTables );
    face->numTables = 0;

    /* freeing the locations table */
    GEO_FREE( face->glyphLocationBlock );
    face->numLocations = 0;

    /* freeing the character mapping tables */
    for ( n = 0; n < face->numCMaps; ++n )
      CharMap_Free( face->cMaps + n );

    FREE( face->cMaps );
    face->numCMaps = 0;

    /* freeing the CVT */
    FREE( face->cvt );
    face->cvtSize = 0;

    /* freeing the horizontal metrics */
    GEO_FREE( face->horizontalHeader.long_metrics_block );
    GEO_FREE( face->horizontalHeader.short_metrics_block );

#ifdef TT_CONFIG_OPTION_PROCESS_VMTX
    /* freeing the vertical ones, if any */
    if (face->verticalInfo)
    {
      FREE( face->verticalHeader.long_metrics  );
      FREE( face->verticalHeader.short_metrics );
      face->verticalInfo = 0;
    }
#endif

    /* freeing the programs */
    FREE( face->fontProgram );
    FREE( face->cvtProgram );
    face->fontPgmSize = 0;
    face->cvtPgmSize  = 0;

#ifdef TT_CONFIG_OPTION_SUPPORT_GASP
    /* freeing the gasp table */
    FREE( face->gasp.gaspRanges );
    face->gasp.numRanges = 0;
#endif

    /* freeing the name table */
    Free_TrueType_Names( face );

#ifdef TT_CONFIG_OPTION_PROCESS_HDMX
    /* freeing the hdmx table */
    Free_TrueType_Hdmx( face );
#endif

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Face_Create
 *
 *  Description :  The face object constructor.
 *
 *  Input  :  _face    face record to build
 *            _input   input stream where to load font data
 *
 *  Output :  Error code.
 *
 *  NOTE : The input stream is kept in the face object.  The
 *         caller shouldn't destroy it after calling Face_Create().
 *
 ******************************************************************/

#undef  LOAD_
#define LOAD_( table ) \
          (error = Load_TrueType_##table (face)) != TT_Err_Ok


  LOCAL_FUNC
  TT_Error  Face_Create( void*  _face,
                         void*  _input )
  {
    TFont_Input*  input = (TFont_Input*)_input;
    PFace         face  = (PFace)_face;
    TT_Error      error;


    face->stream = input->stream;

    Cache_Create( &engineInstance,
                  engineInstance.objs_instance_class,
                  &face->instances );

    Cache_Create( &engineInstance,
                  engineInstance.objs_glyph_class,
                  &face->glyphs );

    /* Load collection directory if present, then font directory */

    error = Load_TrueType_Directory( face );
    if ( error )
      goto Fail;

    /* Load tables */

    if ( LOAD_( Header )        ||
         LOAD_( MaxProfile )    ||
         LOAD_( Locations )     ||

#ifdef TT_CONFIG_OPTION_PROCESS_VMTX
         (error = Load_TrueType_Metrics_Header( face, 0 )) != TT_Err_Ok  ||
         /* load the 'hhea' & 'hmtx' tables at once */
#else
         (error = Load_TrueType_Metrics_Header( face )) != TT_Err_Ok  ||
         /* load the 'hhea' & 'hmtx' tables at once */
#endif

         LOAD_( CMap )          ||
         LOAD_( CVT )           ||
         LOAD_( Programs )      ||
#ifdef TT_CONFIG_OPTION_SUPPORT_GASP
         LOAD_( Gasp )          ||
#endif
         LOAD_( Names )         ||
         LOAD_( OS2 )           ||
         LOAD_( PostScript )

#ifdef TT_CONFIG_OPTION_PROCESS_VMTX
         || (error = Load_TrueType_Metrics_Header( face, 1 )) != TT_Err_Ok
         /* try to load the 'vhea' & 'vmtx' at once if present */
#endif

#ifdef TT_CONFIG_OPTION_PROCESS_HDMX
         || LOAD_( Hdmx ) 
#endif         
         
         )

      goto Fail;

#ifdef TT_CONFIG_OPTION_EXTEND_ENGINE
    if ( ( error = Extension_Create( face ) ) != TT_Err_Ok )
      return error;
#endif

    return TT_Err_Ok;

  Fail :
    Face_Destroy( face );
    return error;
  }

#undef LOAD_


/*******************************************************************
 *
 *  Function    :  Glyph_Destroy
 *
 *  Description :  The glyph object destructor.
 *
 *  Input  :  _glyph  typeless pointer to the glyph record to destroy
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Glyph_Destroy( void*  _glyph )
  {
    PGlyph  glyph = (PGlyph)_glyph;


    if ( !glyph )
      return TT_Err_Ok;

    glyph->outline.owner = TRUE;
    return TT_Done_Outline( &glyph->outline );
  }


/*******************************************************************
 *
 *  Function    :  Glyph_Create
 *
 *  Description :  The glyph object constructor.
 *
 *  Input  :  _glyph   glyph record to build.
 *            _face    the glyph's parent face.
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Glyph_Create( void*  _glyph,
                          void*  _face )
  {
    PFace     face  = (PFace)_face;
    PGlyph    glyph = (PGlyph)_glyph;


    if ( !face )
      return TT_Err_Invalid_Face_Handle;

    if ( !glyph )
      return TT_Err_Invalid_Glyph_Handle;

    glyph->face = face;

    /* XXX: Don't forget the space for the 2 phantom points */
    return TT_New_Outline( glyph->face->maxPoints + 2,
                           glyph->face->maxContours,
                           &glyph->outline );
  }



/*******************************************************************
 *
 *  Function    :  TTObjs_Init
 *
 *  Description :  The TTObjs component initializer.  Creates the
 *                 object cache classes, as well as the face record
 *                 cache.
 *
 *  Input  :  engine    engine instance
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  static
  const TCache_Class  objs_face_class =
  {
    sizeof ( TFace ),
    -1,
    Face_Create,
    Face_Destroy
  };

  static
  const TCache_Class  objs_instance_class =
  {
    sizeof ( TInstance ),
    -1,
    Instance_Create,
    Instance_Destroy
  };

  /* Note that we use a cache size of 1 for the execution context.  */
  /* This is to avoid re-creating a new context each time we        */
  /* change one instance's attribute (resolution and/or char sizes) */
  /* or when we load a glyph.                                       */

  static
  const TCache_Class  objs_exec_class =
  {
    sizeof ( TExecution_Context ),
    1,
    Context_Create,
    Context_Destroy
  };

  static
  const TCache_Class  objs_glyph_class =
  {
    sizeof ( TGlyph ),
    -1,
    Glyph_Create,
    Glyph_Destroy
  };


  LOCAL_FUNC
  TT_Error  TTObjs_Init( PEngine_Instance  engine )
  {
    PCache        face_cache, exec_cache;
    TT_Error      error;


    if ( ALLOC( face_cache, sizeof ( TCache ) ) ||
         ALLOC( exec_cache, sizeof ( TCache ) ) )
      goto Fail;

    /* create face cache */
    error = Cache_Create( engine, (PCache_Class)&objs_face_class, face_cache );
    if ( error )
      goto Fail;

    engine->objs_face_cache = face_cache;

    error = Cache_Create( engine, (PCache_Class)&objs_exec_class, exec_cache );
    if ( error )
      goto Fail;

    engine->objs_exec_cache = exec_cache;

    engine->objs_face_class      = (PCache_Class)&objs_face_class;
    engine->objs_instance_class  = (PCache_Class)&objs_instance_class;
    engine->objs_execution_class = (PCache_Class)&objs_exec_class;
    engine->objs_glyph_class     = (PCache_Class)&objs_glyph_class;

    goto Exit;

  Fail:
    FREE( face_cache );
    FREE( exec_cache );

  Exit:
    return error;
  }


/*******************************************************************
 *
 *  Function    :  TTObjs_Done
 *
 *  Description :  The TTObjs component finalizer.
 *
 *  Input  :  engine    engine instance
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  TTObjs_Done( PEngine_Instance  engine )
  {
    /* destroy all active faces and contexts before releasing the */
    /* caches                                                     */
    Cache_Destroy( (TCache*)engine->objs_exec_cache );
    Cache_Destroy( (TCache*)engine->objs_face_cache );

    /* Now frees caches and cache classes */
    FREE( engine->objs_exec_cache );
    FREE( engine->objs_face_cache );

    return TT_Err_Ok;
  }


/* END */
