/*******************************************************************
 *
 *  ttdebug.h
 *
 *    Debugging and Logging component (specification)
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
 *
 *  This component contains various macros and functions used to
 *  ease the debugging of the FreeType engine. Its main purpose
 *  is in assertion checking, tracing, and error detection.
 *
 *  There are now three debugging modes:
 *
 *  - trace mode:
 *
 *       Error and trace messages are sent to the log file
 *       (which can be the standard error output).  Define
 *       DEBUG_LEVEL_TRACE to enable this mode.
 *
 *  - error mode:
 *
 *       Only error messages are generated.  Define
 *       DEBUG_LEVEL_ERROR to enable this mode.
 *
 *  - release mode:
 *
 *       Error messages are neither sent nor generated. The code is
 *       free from any debugging parts.
 *
 ******************************************************************/

#ifndef TTDEBUG_H
#define TTDEBUG_H

#include "ttconfig.h"
#include "tttypes.h"


#ifdef __cplusplus
  extern "C" {
#endif


#if defined( DEBUG_LEVEL_TRACE )

  typedef enum Trace_Component_
  {
    trace_any = 0,
    trace_api,
    trace_interp,
    trace_load,
    trace_gload,
    trace_memory,
    trace_file,
    trace_mutex,
    trace_cache,
    trace_calc,
    trace_cmap,
    trace_extend,
    trace_objs,
    trace_raster,

    trace_bitmap,
    trace_max

  } Trace_Component;


  /* Here we define an array to hold the trace levels per component. */
  /* Since it is globally defined, all array members are set to 0.   */
  /* You should set the values in this array either in your program  */
  /* or with your debugger.                                          */
  /*                                                                 */
  /* Currently, up to eight levels (PTRACE0-PTRACE7, see below) are  */
  /* used in some parts of the engine.                               */
  /*                                                                 */
  /* For example, to have all tracing messages in the raster         */
  /* component, say                                                  */
  /*                                                                 */
  /*   #define DEBUG_LEVEL_TRACE                                     */
  /*   #include "ttdebug.h"                                          */
  /*                                                                 */
  /*   ...                                                           */
  /*   set_tt_trace_levels( trace_raster, 7 )                        */
  /*                                                                 */
  /* in your code before initializing the FreeType engine.           */
  /*                                                                 */
  /* Maybe it is better to define DEBUG_LEVEL_TRACE in ttconfig.h... */

  extern char  tt_trace_levels[trace_max];

  /* IMPORTANT:                                                 */
  /*                                                            */
  /*  Each component must define the macro TT_COMPONENT         */
  /*  to a valid Trace_Component value before using any         */
  /*  PTRACEx macro.                                            */
  /*                                                            */

#define  PTRACE( level, varformat )  \
         if ( tt_trace_levels[TT_COMPONENT] >= level ) TT_Message##varformat

#elif defined( DEBUG_LEVEL_ERROR )

#define  PTRACE( level, varformat )  /* nothing */

#else  /* RELEASE MODE */

#define TT_Assert( condition, action )  /* nothing */

#define PTRACE( level, varformat )      /* nothing */
#define PERROR( varformat )             /* nothing */
#define PANIC( varformat )              /* nothing */

#endif


/************************************************************************/
/*                                                                      */
/*  Define macros and fuctions that are common to the debug and trace   */
/*  modes.                                                              */
/*                                                                      */

#if defined( DEBUG_LEVEL_TRACE ) || defined( DEBUG_LEVEL_ERROR )


#define TT_Assert( condition, action )  if ( !(condition) ) ( action )

  void  TT_Message( const String*  fmt, ... );
  void  TT_Panic  ( const String*  fmt, ... );
  /* print a message and exit */

  const String*  Cur_U_Line( void*  exec );

#define PERROR( varformat )  TT_Message##varformat
#define PANIC( varformat )   TT_Panic##varformat

#endif

#if defined( DEBUG_LEVEL_TRACE )

  void  set_tt_trace_levels( int  index, char  value );

#endif


#define  PTRACE0( varformat )  PTRACE( 0, varformat )
#define  PTRACE1( varformat )  PTRACE( 1, varformat )
#define  PTRACE2( varformat )  PTRACE( 2, varformat )
#define  PTRACE3( varformat )  PTRACE( 3, varformat )
#define  PTRACE4( varformat )  PTRACE( 4, varformat )
#define  PTRACE5( varformat )  PTRACE( 5, varformat )
#define  PTRACE6( varformat )  PTRACE( 6, varformat )
#define  PTRACE7( varformat )  PTRACE( 7, varformat )


#ifdef __cplusplus
  }
#endif


#endif /* TTDEBUG_H */
