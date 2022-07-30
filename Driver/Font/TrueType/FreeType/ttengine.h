/*******************************************************************
 *
 *  ttengine.h                                                   1.1
 *
 *    Engine instance structure definition.
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
 *  New in 1.1 :
 *
 *    - added the 'raster_lock' mutex field to synchronize
 *      scan-line conversion in thread-safe and re-entrant builds.
 *
 ******************************************************************/

#ifndef TTENGINE_H
#define TTENGINE_H

#include "tttypes.h"
#include "ttconfig.h"
#include "freetype.h"
#include "ttmutex.h"

#ifdef __cplusplus
  extern "C" {
#endif

  /********************************************************************/
  /*                                                                  */
  /*  The freetype engine instance structure.                         */
  /*                                                                  */
  /*  This structure holds all the data that is necessary to run      */
  /*  one instance of the freetype engine.  It is needed to get a     */
  /*  completely re-entrant version of the library.                   */
  /*                                                                  */
  /*  The goal is to move _all_ component-specific variables, either  */
  /*  static or global in the structure; the component initializers   */
  /*  and finalizers will all be called with the address of a valid   */
  /*  TEngine_Instance.                                               */
  /*                                                                  */
  /********************************************************************/

  struct  TEngine_Instance_
  {
     TMutex  lock;               /* engine lock */

     void*   list_free_elements;

     void*   objs_face_class;       /* the face cache class     */
     void*   objs_instance_class;   /* the instance cache class */
     void*   objs_execution_class;  /* the context cache class  */
     void*   objs_glyph_class;      /* the glyph cache class    */

     void*   objs_face_cache;  /* these caches are used to track */
     void*   objs_exec_cache;  /* the current face and execution */
                               /* context objects                */

     void*   file_component;    /* ttfile implementation dependent   */

     TMutex  raster_lock;       /* mutex for this engine's render pool   */
     void*   raster_component;  /* ttraster implementation depedent      */

     void*   extension_component;  /* extensions dependent */

#if 0
     TT_Glyph_Loader_Callback  glCallback; /* glyph loader callback, if any */
#endif
  };

  /* NOTE : The raster's lock is only acquired by the Render_Glyph and     */
  /*        Render_Gray_Glyph functions, which always release it on exit   */
  /*        They do not lock the engine mutex. This means you shouldn't    */
  /*        be concerned about deadlocks between the two mutexes, as these */
  /*        should never appear..                                          */

  typedef struct TEngine_Instance_  TEngine_Instance;
  typedef TEngine_Instance*         PEngine_Instance;


#ifdef TT_CONFIG_OPTION_THREAD_SAFE  /* for re-entrant builds */

#define ENGINE_ARG    TEngine_Instance*  _engine
#define ENGINE_ARGS   TEngine_Instance*  _engine,

#define ENGINE_VAR   _engine
#define ENGINE_VARS  _engine,

#define ENGINE  _engine

#else                       /* for thread-safe builds */

#define ENGINE_ARG    /* void */
#define ENGINE_ARGS

#define ENGINE_VAR
#define ENGINE_VARS

#endif /* TT_CONFIG_OPTION_THREAD_SAFE */

#ifdef __cplusplus
  }
#endif

#endif /* TTENGINE_H */


/* END */
