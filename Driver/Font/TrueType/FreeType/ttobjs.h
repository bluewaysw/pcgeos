/*******************************************************************
 *
 *  ttobjs.h                                                     1.0
 *
 *    Objects definition unit.
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

#ifndef TTOBJS_H
#define TTOBJS_H

#include "ttconfig.h"
#include "ttengine.h"
#include "ttcache.h"
#include "tttables.h"
#include "ttcmap.h"
#include <heap.h>

#ifdef __cplusplus
  extern "C" {
#endif

/*                                                                       */
/*  This file contains the definitions and methods of the four           */
/*  kinds of objects managed by the FreeType engine.  These are:         */
/*                                                                       */
/*                                                                       */
/*   Face objects:                                                       */
/*                                                                       */
/*     There is always one face object per opened TrueType font          */
/*     file, and only one.  The face object contains data that is        */
/*     independent of current transform/scaling/rotation and             */
/*     pointsize, or glyph index.  This data is made of several          */
/*     critical tables that are loaded on face object creation.          */
/*                                                                       */
/*     A face object tracks all active and recycled objects of           */
/*     the instance and execution context classes.  Destroying a face    */
/*     object will automatically destroy all associated instances.       */
/*                                                                       */
/*                                                                       */
/*   Instance objects:                                                   */
/*                                                                       */
/*     An instance object always relates to a given face object,         */
/*     known as its 'parent' or 'owner', and contains only the           */
/*     data that is specific to one given pointsize/transform of         */
/*     the face.  You can only create an instance from a face object.    */
/*                                                                       */
/*     An instance's current transform/pointsize can be changed          */
/*     at any time using a single high-level API call,                   */
/*     TT_Reset_Instance().                                              */
/*                                                                       */
/*   Execution Context objects:                                          */
/*                                                                       */
/*     An execution context (or context in short) relates to a face.     */
/*     It contains the data and tables that are necessary to load        */
/*     and hint (i.e. execute the glyph instructions of) one glyph.      */
/*     A context is a transient object that is queried/created on        */
/*     the fly: client applications never deal with them directly.       */
/*                                                                       */
/*                                                                       */
/*   Glyph objects:                                                      */
/*                                                                       */
/*     A glyph object contains only the minimal glyph information        */
/*     needed to render one glyph correctly.  This means that a glyph    */
/*     object really contains tables that are sized to hold the          */
/*     contents of _any_ glyph of a given face.  A client application    */
/*     can usually create one glyph object for a given face, then use    */
/*     it for all subsequent loads.                                      */
/*                                                                       */
/*   Here is an example of a client application :                        */
/*   (NOTE: No error checking performed here!)                           */
/*                                                                       */
/*                                                                       */
/*     TT_Face       face;         -- face handle                        */
/*     TT_Instance   ins1, ins2;   -- two instance handles               */
/*     TT_Glyph      glyph;        -- glyph handle                       */
/*                                                                       */
/*     TT_Init_FreeType();                                               */
/*                                                                       */
/*     -- Initialize the engine.  This must be done prior to _any_       */
/*        operation.                                                     */
/*                                                                       */
/*     TT_Open_Face( "/some/face/name.ttf", &face );                     */
/*                                                                       */
/*     -- create the face object.  This call opens the font file         */
/*                                                                       */
/*     TT_New_Instance( face, &ins1 );                                   */
/*     TT_New_Instance( face, &ins2 );                                   */
/*                                                                       */
/*     TT_Set_Instance_PointSize( ins1, 8 );                             */
/*     TT_Set_Instance_PointSize( ins2, 12 );                            */
/*                                                                       */
/*     -- create two distinct instances of the same face                 */
/*     -- ins1  is pointsize 8 at resolution 96 dpi                      */
/*     -- ins2  is pointsize 12 at resolution 96 dpi                     */
/*                                                                       */
/*     TT_New_Glyph( face, &glyph );                                     */
/*                                                                       */
/*     -- create a new glyph object which will receive the contents      */
/*        of any glyph of 'face'                                         */
/*                                                                       */
/*     TT_Load_Glyph( ins1, glyph, 64, DEFAULT_GLYPH_LOAD );             */
/*                                                                       */
/*     -- load glyph indexed 64 at pointsize 8 in the 'glyph' object     */
/*     -- NOTE: This call will fail if the instance and the glyph        */
/*              do not relate to the same face object.                   */
/*                                                                       */
/*     TT_Get_Outline( glyph, &outline );                                */
/*                                                                       */
/*     -- extract the glyph outline from the object and copies it        */
/*        to the 'outline' record                                        */
/*                                                                       */
/*     TT_Get_Metrics( glyph, &metrics );                                */
/*                                                                       */
/*     -- extract the glyph metrics and put them into the 'metrics'      */
/*        record                                                         */
/*                                                                       */
/*     TT_Load_Glyph( ins2, glyph, 64, DEFAULT_GLYPH_LOAD );             */
/*                                                                       */
/*     -- load the same glyph at pointsize 12 in the 'glyph' object      */
/*                                                                       */
/*                                                                       */
/*     TT_Close_Face( &face );                                           */
/*                                                                       */
/*     -- destroy the face object.  This will destroy 'ins1' and         */
/*        'ins2'.  However, the glyph object will still be available     */
/*                                                                       */
/*     TT_Done_FreeType();                                               */
/*                                                                       */
/*     -- Finalize the engine.  This will also destroy all pending       */
/*        glyph objects (here 'glyph').                                  */

  struct TFace_;
  struct TInstance_;
  struct TExecution_Context_;
  struct TGlyph_;

  typedef struct TFace_  TFace;
  typedef TFace*         PFace;

  typedef struct TInstance_  TInstance;
  typedef TInstance*         PInstance;

  typedef struct TExecution_Context_  TExecution_Context;
  typedef TExecution_Context*         PExecution_Context;

  typedef struct TGlyph_  TGlyph;
  typedef TGlyph*         PGlyph;


  /*************************************************************/
  /*                                                           */
  /*  ADDITIONAL SUBTABLES                                     */
  /*                                                           */
  /*  These tables are not precisely defined by the specs      */
  /*  but their structures is implied by the TrueType font     */
  /*  file layout.                                             */
  /*                                                           */
  /*************************************************************/

  /* Graphics State                            */
  /*                                           */
  /* The Graphics State (GS) is managed by the */
  /* instruction field, but does not come from */
  /* the font file.  Thus, we can use 'int's   */
  /* where needed.                             */

  struct  TGraphicsState_
  {
    UShort         rp0;
    UShort         rp1;
    UShort         rp2;

    TT_UnitVector  dualVector;
    TT_UnitVector  projVector;
    TT_UnitVector  freeVector;

    Int            loop;
    TT_F26Dot6     minimum_distance;
    Int            round_state;

    Bool           auto_flip;
    TT_F26Dot6     control_value_cutin;
    TT_F26Dot6     single_width_cutin;
    TT_F26Dot6     single_width_value;
    Short          delta_base;
    Short          delta_shift;

    Byte           instruct_control;
    Bool           scan_control;
    Int            scan_type;

    UShort         gep0;
    UShort         gep1;
    UShort         gep2;
  };

  typedef struct TGraphicsState_  TGraphicsState;


  LOCAL_DEF
  const TGraphicsState  Default_GraphicsState;


  /*************************************************************/
  /*                                                           */
  /*  EXECUTION SUBTABLES                                      */
  /*                                                           */
  /*  These sub-tables relate to instruction execution.        */
  /*                                                           */
  /*************************************************************/

#define MAX_CODE_RANGES   3

/* There can only be 3 active code ranges at once:   */
/*   - the Font Program                              */
/*   - the CVT Program                               */
/*   - a glyph's instructions set                    */

#define TT_CodeRange_Font  1
#define TT_CodeRange_Cvt   2
#define TT_CodeRange_Glyph 3


  struct  TCodeRange_
  {
    PByte   Base;
    UShort  Size;
  };

  typedef struct TCodeRange_  TCodeRange;
  typedef TCodeRange*         PCodeRange;


  /* Defintion of a code range                                       */
  /*                                                                 */
  /* Code ranges can be resident to a glyph (i.e. the Font Program)  */
  /* while some others are volatile (Glyph instructions).            */
  /* Tracking the state and presence of code ranges allows function  */
  /* and instruction definitions within a code range to be forgotten */
  /* when the range is discarded.                                    */

  typedef TCodeRange  TCodeRangeTable[MAX_CODE_RANGES];

  /* defines a function/instruction definition record */

  struct  TDefRecord_
  {
    Int    Range;     /* in which code range is it located ? */
    UShort Start;     /* where does it start ?               */
    Int    Opc;       /* function #, or instruction code     */
    Bool   Active;    /* is it active ?                      */
  };

  typedef struct TDefRecord_  TDefRecord;
  typedef TDefRecord*         PDefRecord;
  typedef TDefRecord*         PDefArray;

  /* defines a call record, used to manage function calls. */

  struct  TCallRecord_
  {
    Int    Caller_Range;
    UShort Caller_IP;
    Short  Cur_Count;
    UShort Cur_Restart;
  };

  typedef struct TCallRecord_  TCallRecord;
  typedef TCallRecord*         PCallRecord;
  typedef TCallRecord*         PCallStack;  /* defines a simple call stack */


  /* This type defining a set of glyph points will be used to represent */
  /* each zone (regular and twilight) during instructions decoding.     */
  struct  TGlyph_Zone_
  {
    UShort        n_points;   /* number of points in zone */
    Short         n_contours; /* number of contours       */

    TT_Vector*    org;        /* original points coordinates */
    TT_Vector*    cur;        /* current points coordinates  */

    Byte*         touch;      /* current touch flags         */
    UShort*       contours;   /* contour end points          */
  };

  typedef struct TGlyph_Zone_  TGlyph_Zone;
  typedef TGlyph_Zone*         PGlyph_Zone;



#ifndef TT_STATIC_INTEPRETER  /* indirect implementation */

#define EXEC_OPS   PExecution_Context exc,
#define EXEC_OP    PExecution_Context exc
#define EXEC_ARGS  exc,
#define EXEC_ARG   exc

#else                          /* static implementation */

#define EXEC_OPS   /* void */
#define EXEC_OP    /* void */
#define EXEC_ARGS  /* void */
#define EXEC_ARG   /* void */

#endif

#define CALL_INTERPRETER  ( engineInstance.interpreterActive ? RunIns( exec ) : TT_Err_Ok )

  /* Rounding function, as used by the interpreter */
  typedef TT_F26Dot6  TRound_Function( EXEC_OPS TT_F26Dot6 distance,
                                                TT_F26Dot6 compensation );

  /* Point displacement along the freedom vector routine, as */
  /* used by the interpreter                                 */
  typedef void  TMove_Function( EXEC_OPS PGlyph_Zone  zone,
                                         UShort       point,
                                         TT_F26Dot6   distance );

  /* Distance projection along one of the proj. vectors, as used */
  /* by the interpreter                                          */
  typedef TT_F26Dot6  TProject_Function( EXEC_OPS TT_Vector*  v1,
                                                  TT_Vector*  v2 );

  /* reading a cvt value. Take care of non-square pixels when needed */
  typedef TT_F26Dot6  TGet_CVT_Function( EXEC_OPS UShort  index );

  /* setting or moving a cvt value.  Take care of non-square pixels  */
  /* when needed                                                     */
  typedef void  TSet_CVT_Function ( EXEC_OPS  UShort      index,
                                              TT_F26Dot6  value );

  /* subglyph transformation record */
  struct  TTransform_
  {
    TT_Fixed    xx, xy; /* transformation */
    TT_Fixed    yx, yy; /*     matrix     */
    TT_F26Dot6  ox, oy; /*    offsets     */
  };

  typedef struct TTransform_  TTransform;
  typedef TTransform*         PTransform;

  /* subglyph loading record.  Used to load composite components */
  struct  TSubglyph_Record_
  {
    Short        index;        /* subglyph index; initialized with -1 */
    Bool         is_scaled;    /* is the subglyph scaled?  */
    Bool         is_hinted;    /* should it be hinted?     */
    Bool         preserve_pps; /* preserve phantom points? */

    Long         file_offset;

    TT_Big_Glyph_Metrics  metrics;

    TGlyph_Zone  zone;

    Long         arg1;  /* first argument  */
    Long         arg2;  /* second argument */

    UShort       element_flag;    /* current load element flag */

    TTransform   transform;       /* transform */

    TT_Vector    pp1, pp2;        /* phantom points */

  };

  typedef struct TSubglyph_Record_  TSubglyph_Record;
  typedef TSubglyph_Record*         PSubglyph_Record;
  typedef TSubglyph_Record*         PSubglyph_Stack;

  /* A note regarding non-squared pixels:                                */
  /*                                                                     */
  /* (This text will probably go into some docs at some time, for        */
  /*  now, it is kept there to explain some definitions in the           */
  /*  TIns_Metrics record).                                              */
  /*                                                                     */
  /* The CVT is a one-dimensional array containing values that           */
  /* control certain important characteristics in a font, like           */
  /* the height of all capitals, all lowercase letter, default           */
  /* spacing or stem width/height.                                       */
  /*                                                                     */
  /* These values are found in FUnits in the font file, and must be      */
  /* scaled to pixel coordinates before being used by the CVT and        */
  /* glyph programs.  Unfortunately, when using distinct x and y         */
  /* resolutions (or distinct x and y pointsizes), there are two         */
  /* possible scalings.                                                  */
  /*                                                                     */
  /* A first try was to implement a 'lazy' scheme where all values       */
  /* were scaled when first used.  However, while some values are always */
  /* used in the same direction, and some other are used in many         */
  /* different circumstances and orientations.                           */
  /*                                                                     */
  /* I have found a simpler way to do the same, and it even seems to     */
  /* work in most of the cases:                                          */
  /*                                                                     */
  /* - all CVT values are scaled to the maximum ppem size                */
  /*                                                                     */
  /* - when performing a read or write in the CVT, a ratio factor        */
  /*   is used to perform adequate scaling. Example:                     */
  /*                                                                     */
  /*    x_ppem = 14                                                      */
  /*    y_ppem = 10                                                      */
  /*                                                                     */
  /*   we choose ppem = x_ppem = 14 as the CVT scaling size.  All cvt    */
  /*   entries are scaled to it.                                         */
  /*                                                                     */
  /*    x_ratio = 1.0                                                    */
  /*    y_ratio = y_ppem/ppem (< 1.0)                                    */
  /*                                                                     */
  /*   we compute the current ratio like:                                */
  /*                                                                     */
  /*     - if projVector is horizontal,                                  */
  /*         ratio = x_ratio = 1.0                                       */
  /*     - if projVector is vertical,                                    */
  /*         ratop = y_ratio                                             */
  /*     - else,                                                         */
  /*         ratio = sqrt((proj.x*x_ratio)^2 + (proj.y*y_ratio)^2)       */
  /*                                                                     */
  /*   reading a cvt value returns      ratio * cvt[index]               */
  /*   writing a cvt value in pixels    cvt[index] / ratio               */
  /*                                                                     */
  /*   the current ppem is simply       ratio * ppem                     */
  /*                                                                     */

  /* metrics used by the instance and execution context objects */
  struct  TIns_Metrics_
  {
    TT_F26Dot6  pointSize;      /* point size.  1 point = 1/72 inch. */

    UShort      x_resolution;   /* device horizontal resolution in dpi. */
    UShort      y_resolution;   /* device vertical resolution in dpi.   */

    UShort      x_ppem;         /* horizontal pixels per EM */
    UShort      y_ppem;         /* vertical pixels per EM   */

    Long        x_scale1;
    Long        x_scale2;    /* used to scale FUnits to fractional pixels */

    Long        y_scale1;
    Long        y_scale2;    /* used to scale FUnits to fractional pixels */

    /* for non-square pixels */
    Long        x_ratio;
    Long        y_ratio;

    UShort      ppem;        /* maximum ppem size */
    Long        ratio;       /* current ratio     */
    Long        scale1;
    Long        scale2;      /* scale for ppem */

    TT_F26Dot6  compensations[4];  /* device-specific compensations */
  };

  typedef struct TIns_Metrics_  TIns_Metrics;
  typedef TIns_Metrics*         PIns_Metrics;



  /***********************************************************************/
  /*                                                                     */
  /*                         FreeType Face Type                          */
  /*                                                                     */
  /***********************************************************************/

  struct  TFace_
  {
    /* i/o stream */
    TT_Stream  stream;

    /* maximum profile table, as found in the TrueType file */
    TMaxProfile  maxProfile;

    /* Note:                                          */
    /*  it seems that some maximum values cannot be   */
    /*  taken directly from this table, but rather by */
    /*  combining some of its fields; e.g. the max.   */
    /*  number of points seems to be given by         */
    /*  MAX( maxPoints, maxCompositePoints )          */
    /*                                                */
    /*  For this reason, we define later our own      */
    /*  max values that are used to load and allocate */
    /*  further tables.                               */

    TT_Header             fontHeader;           /* the font header, as   */
                                                /* found in the TTF file */
    TT_Horizontal_Header  horizontalHeader;     /* the horizontal header */

#ifdef TT_CONFIG_OPTION_PROCESS_VMTX
    Bool                  verticalInfo;         /* True when vertical table */
    TT_Vertical_Header    verticalHeader;       /* is present in the font   */
#endif

    TT_OS2                os2;                  /* 'OS/2' table */

    TT_Postscript         postscript;           /* 'Post' table */

#ifdef TT_CONFIG_OPTION_PROCESS_HDMX
    TT_Hdmx               hdmx;                 /* 'Hdmx' table */
#endif

    TName_Table           nameTable;            /* name table */

#ifdef TT_CONFIG_OPTION_SUPPORT_GASP
    TGasp                 gasp;                 /* the 'gasp' table */
#endif

    /* The directory of TrueType tables for this typeface */
    UShort          numTables;
    PTableDirEntry  dirTables;

    /* The directory of character mappings table for */
    /* this typeface                                 */
    UShort      numCMaps;
    PCMapTable  cMaps;

    /* The glyph locations table */
    UShort    numLocations;
    MemHandle glyphLocationBlock;

    /* NOTE : The "hmtx" is now part of the horizontal header */

    /* the font program, if any */
    UShort  fontPgmSize;
    PByte   fontProgram;

    /* the cvt program, if any */
    UShort  cvtPgmSize;
    PByte   cvtProgram;

    /* the original, unscaled, control value table */
    UShort  cvtSize;
    PShort  cvt;

    /* The following values _must_ be set by the */
    /* maximum profile loader                    */

    UShort  numGlyphs;     /* the face's total number of glyphs */
    UShort  maxPoints;     /* max glyph points number, simple and composite */
    UShort  maxContours;   /* max glyph contours numb, simple and composite */
    UShort  maxComponents; /* max components in a composite glyph */

    /* the following are object caches to track active */
    /* and recycled instances and execution contexts   */
    /* objects.  See 'ttcache.h'                       */

    TCache  instances;   /* current instances for this face */
    TCache  glyphs;      /* current glyph containers for this face */

    /* A typeless pointer to the face object extensions defined */
    /* in the 'ttextend.*' files.                               */
  #ifdef TT_CONFIG_OPTION_EXTEND_ENGINE
    void*  extension;
    Int    n_extensions;    /* number of extensions */
  #endif
  };



  /***********************************************************************/
  /*                                                                     */
  /*                       FreeType Instance Type                        */
  /*                                                                     */
  /***********************************************************************/

  struct  TInstance_
  {
    PFace            owner;     /* face object */

    Bool             valid;

    TIns_Metrics     metrics;

    UShort           numFDefs;  /* number of function definitions */
    UShort           maxFDefs;
    PDefArray        FDefs;     /* table of FDefs entries         */

    UShort           numIDefs;  /* number of instruction definitions */
    UShort           maxIDefs;
    PDefArray        IDefs;     /* table of IDefs entries            */

    Int              maxFunc;   /* maximum function definition id    */
    Int              maxIns;    /* maximum instruction definition id */

    TCodeRangeTable  codeRangeTable;

    TGraphicsState   GS;
    TGraphicsState   default_GS;

    UShort           cvtSize;   /* the scaled control value table */
    PLong            cvt;

    UShort           storeSize; /* The storage area is now part of the */
    PLong            storage;   /* instance                            */

    TGlyph_Zone      twilight;  /* The instance's twilight zone */
  };


  /***********************************************************************/
  /*                                                                     */
  /*                  FreeType Execution Context Type                    */
  /*                                                                     */
  /***********************************************************************/

  struct  TExecution_Context_
  {
    PFace           face;
    PInstance       instance;

    /* instructions state */

    TT_Error        error;     /* last execution error */

    Short           top;        /* top of exec. stack  */

    UShort          stackSize;  /* size of exec. stack */
    PStorage        stack;      /* current exec. stack */

    Short           args;
    UShort          new_top;    /* new top after exec.    */

    TGlyph_Zone     zp0,            /* zone records */
                    zp1,
                    zp2,
                    pts,
                    twilight;

    TIns_Metrics    metrics;       /* instance metrics */

    TGraphicsState  GS;            /* current graphics state */

    Int             curRange;  /* current code range number   */
    PByte           code;      /* current code range          */
    UShort          IP;        /* current instruction pointer */
    UShort          codeSize;  /* size of current range       */

    Byte            opcode;    /* current opcode              */
    Int             length;    /* length of current opcode    */

    Bool            step_ins;  /* true if the interpreter must */
                               /* increment IP after ins. exec */
    UShort          cvtSize;
    PLong           cvt;

    UShort          glyphSize; /* glyph instructions buffer size */
    PByte           glyphIns;  /* glyph instructions buffer */

    UShort          numFDefs;  /* number of function defs         */
    UShort          maxFDefs;  /* maximum number of function defs */
    PDefRecord      FDefs;     /* table of FDefs entries          */

    UShort          numIDefs;  /* number of instruction defs         */
    UShort          maxIDefs;  /* maximum number of instruction defs */
    PDefRecord      IDefs;     /* table of IDefs entries             */

    Int             maxFunc;
    Int             maxIns;

    Int             callTop,    /* top of call stack during execution */
                    callSize;   /* size of call stack */
    PCallStack      callStack;  /* call stack */

    UShort          maxPoints;    /* capacity of this context's "pts" */
    UShort          maxContours;  /* record, expressed in points and  */
                                  /* contours..                       */

    TCodeRangeTable codeRangeTable;  /* table of valid coderanges */
                                     /* useful for the debugger   */

    UShort          storeSize;  /* size of current storage */
    PLong           storage;    /* storage area            */

    TT_F26Dot6      period;     /* values used for the */
    TT_F26Dot6      phase;      /* 'SuperRounding'     */
    TT_F26Dot6      threshold;

    Long            scale1;         /* scaling values along the current   */
    Long            scale2;         /* projection vector too..            */
    Bool            cached_metrics; /* the ppem is computed lazily. used  */
                                    /* to trigger computation when needed */

    Bool            instruction_trap;  /* If True, the interpreter will */
                                       /* exit after each instruction   */

    TGraphicsState  default_GS;    /* graphics state resulting from  */
                                   /* the prep program               */
    Bool            is_composite;  /* ture if the glyph is composite */

#ifdef TT_CONFIG_OPTION_SUPPORT_PEDANTIC_HINTING
   Bool            pedantic_hinting;  /* if true, read and write array   */
#endif                                /* bounds faults halt the hinting  */

    /* latest interpreter additions */

    Long               F_dot_P;    /* dot product of freedom and projection */
                                   /* vectors                               */
    TRound_Function    _near * func_round;     /* current rounding function   */

    TProject_Function  _near * func_project;   /* current projection function */
    TProject_Function  _near * func_dualproj;  /* current dual proj. function */

    TMove_Function     _near * func_move;      /* current point move function */

    TGet_CVT_Function  _near * func_read_cvt;  /* read a cvt entry              */
    TSet_CVT_Function  _near * func_write_cvt; /* write a cvt entry (in pixels) */
    TSet_CVT_Function  _near * func_move_cvt;  /* incr a cvt entry (in pixels)  */

    UShort             loadSize;
    PSubglyph_Stack    loadStack;      /* loading subglyph stack */

  };


  /***********************************************************************/
  /*                                                                     */
  /*                  FreeType Glyph Object Type                         */
  /*                                                                     */
  /***********************************************************************/

  struct TGlyph_
  {
    PFace                 face;
    TT_Big_Glyph_Metrics  metrics;
    TT_Outline            outline;
  };


  /* The following type is used to load a font from a collection. */
  /* See Face_Create in ttobjs.c                                  */

  struct  TFont_Input_
  {
    TT_Stream         stream;     /* input stream                */
  };

  typedef struct TFont_Input_  TFont_Input;


  /********************************************************************/
  /*                                                                  */
  /*   Code Range Functions                                           */
  /*                                                                  */
  /********************************************************************/

  /* Goto a specified coderange */
  LOCAL_DEF
  TT_Error  Goto_CodeRange( PExecution_Context  exec,
                            Int                 range,
                            UShort              IP );


  /* Set a given code range properties */
  LOCAL_DEF
  TT_Error  Set_CodeRange( PExecution_Context  exec,
                           Int                 range,
                           void*               base,
                           UShort              length );

  /* Clear a given coderange */
  LOCAL_DEF
  TT_Error  Clear_CodeRange( PExecution_Context  exec, Int  range );


  LOCAL_DEF
  PExecution_Context  New_Context( PFace  face );

  LOCAL_DEF
  TT_Error  Done_Context( PExecution_Context  exec );


  LOCAL_DEF
  TT_Error  Context_Load( PExecution_Context  exec,
                          PFace               face,
                          PInstance           ins );

  LOCAL_DEF
  TT_Error  Context_Save( PExecution_Context  exec,
                          PInstance           ins );

  LOCAL_DEF
  TT_Error  Context_Run( PExecution_Context  exec );

  LOCAL_DEF
  TT_Error  Instance_Init( PInstance  ins );

  LOCAL_DEF
  TT_Error  Instance_Reset( PInstance  ins );


  /********************************************************************/
  /*                                                                  */
  /*   Component Initializer/Finalizer                                */
  /*                                                                  */
  /*   Called from 'freetype.c'                                       */
  /*   The component must create and register the face, instance and  */
  /*   execution context cache classes before any object can be       */
  /*   managed.                                                       */
  /*                                                                  */
  /********************************************************************/

  LOCAL_DEF TT_Error  TTObjs_Init( );
  LOCAL_DEF TT_Error  TTObjs_Done( );

#ifdef __cplusplus
  }
#endif

#endif /* TTOBJS_H */


/* END */
