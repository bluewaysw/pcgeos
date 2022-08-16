/*******************************************************************
 *
 *  ttextend.h                                                   2.0
 *
 *    Extensions Interface.
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
 *  This is an updated version of the extension component, now
 *  located in the main library's source directory.  It allows
 *  the dynamic registration/use of various face object extensions
 *  through a simple API.
 *
 ******************************************************************/

#ifndef TTEXTEND_H
#define TTEXTEND_H

#include "ttconfig.h"
#include "tttypes.h"
#include "ttobjs.h"


#ifdef __cplusplus
  extern "C" {
#endif

  /* The extensions don't need to be integrated at compile time into */
  /* the engine, only at link time.                                  */


  /* When a new face object is created, the face constructor calls */
  /* the extension constructor with the following arguments:       */
  /*                                                               */
  /*   ext  : typeless pointer to the face's extension block.      */
  /*          Its size is the one given at registration time       */
  /*          in the extension class's 'size' field.               */
  /*                                                               */
  /*   face : the parent face object.  Note that the extension     */
  /*          constructor is called when the face object is        */
  /*          built.                                               */

  typedef TT_Error  TExt_Constructor( void*  ext, PFace  face );


  /* When a face object is destroyed, the face destructor calls    */
  /* the extension destructor with the following arguments.        */
  /*                                                               */
  /*   ext  : typeless pointer to the face's extension block.      */
  /*          Its size is the one given at registration time       */
  /*          in the extension class's 'size' field.               */
  /*                                                               */
  /*   face : the parent face object.  Note that the extension     */
  /*          destructor is called before the actual face object   */
  /*          is destroyed.                                        */

  typedef TT_Error  TExt_Destructor ( void*  ext, PFace  face );

  typedef TExt_Constructor*  PExt_Constructor;
  typedef TExt_Destructor*   PExt_Destructor;


  struct TExtension_Class_
  {
    Long              id;      /* extension id                      */
    Long              size;    /* size in bytes of extension record */
    PExt_Constructor  build;   /* the extension's class constructor */
    PExt_Destructor   destroy; /* the extension's class destructor  */

    Long              offset;  /* offset of ext. record in face obj */
                               /* (set by the engine)               */
  };

  typedef struct TExtension_Class_  TExtension_Class;
  typedef TExtension_Class*         PExtension_Class;


#define Build_Extension_ID( a, b, c, d ) \
           ( ((ULong)(a) << 24) |        \
             ((ULong)(b) << 16) |        \
             ((ULong)(c) << 8 ) |        \
              (ULong)(d) )

  /*  A note regarding extensions and the single-object compilation    */
  /*  mode :                                                           */
  /*                                                                   */
  /*  When the engine is compiled as a single object file, extensions  */
  /*  must remain linkable *after* compile time. In order to do this,  */
  /*  we need to export the functions that an extension may need.      */
  /*  Fortunately, we can limit ourselves to :                         */
  /*                                                                   */
  /*  o TT_Register_Extension (previously called Extension_Register)   */
  /*        which is to be called by each extension on within          */
  /*        it TT_Init_XXXX_Extension initializer.                     */
  /*                                                                   */
  /*  o File and frame access functions. Fortunately, these already    */
  /*    have their names prefixed by "TT_", so no change was needed    */
  /*    except replacing the LOCAL_DEF keyword with EXPORT_DEF         */
  /*                                                                   */
  /*  o Memory access functions, i.e. TT_Alloc and TT_Free. Again,     */
  /*    the change is minimal                                          */
  /*                                                                   */
  /*  o the table-lookup function : TT_LookUp_Table, formerly known    */
  /*    as Load_TrueType_Table in ttload.c.                            */
  /*                                                                   */
  /*                                                                   */
  /*  Other than that, an extension should be able to #include all     */
  /*  relevant header files to get access to internal types, but       */
  /*  should not call engine internal functions..                      */
  /*                                                                   */
  /*  If there is a need for a specific internal function call, let    */
  /*  me known to see if we need to export it by default..             */
  /*                                                         - DavidT  */
  /*                                                                   */

  /* Register a new extension.  Called by extension */
  /* service initializers.                          */
  EXPORT_DEF
  TT_Error  TT_Register_Extension( PEngine_Instance  engine,
                                   Long              id,
                                   Long              size,
                                   PExt_Constructor  create,
                                   PExt_Destructor   destroy );


#ifdef TT_CONFIG_OPTION_EXTEND_ENGINE
  /* Initialize the extension component */
  LOCAL_DEF
  TT_Error  TTExtend_Init( TT_Engine  engine );

  /* Finalize the extension component */
  LOCAL_DEF
  TT_Error  TTExtend_Done( PEngine_Instance  engine );

  /* Create an extension within a face object.  Called by the */
  /* face object constructor.                                 */
  LOCAL_DEF
  TT_Error  Extension_Create( PFace  face );

  /* Destroy all extensions within a face object.  Called by the */
  /* face object destructor.                                     */
  LOCAL_DEF
  TT_Error  Extension_Destroy( PFace  face );
#endif

  /* Query an extension block by extension_ID.  Called by extension */
  /* service routines.                                              */
  EXPORT_DEF
  TT_Error  TT_Extension_Get( PFace   face,
                              Long    extension_id,
                              void**  extension_block );

#ifdef __cplusplus
  }
#endif


#endif /* TTEXTEND_H */


/* END */
