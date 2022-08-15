/*******************************************************************
 *
 *  ttextend.h                                                   2.0
 *
 *    Extensions Interface
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

#include "ttextend.h"
#include "ttengine.h"
#include "ttmemory.h"

/* required by the tracing mode */
#undef  TT_COMPONENT
#define TT_COMPONENT      trace_extend


  struct TExtension_Registry_
  {
    Int               num_extensions;
    Long              cur_offset;
    TExtension_Class  classes[TT_MAX_EXTENSIONS];
  };

  typedef struct TExtension_Registry_  TExtension_Registry;
  typedef TExtension_Registry*         PExtension_Registry;



  /* Initialize the extension component */

  LOCAL_FUNC
  TT_Error  TTExtend_Init( PEngine_Instance  engine )
  {
    TT_Error             error;
    PExtension_Registry  exts;


    if ( ALLOC( exts, sizeof ( TExtension_Registry ) ) )
      return error;
    
    ECCheckBounds( exts );

    exts->num_extensions        = 0;
    exts->cur_offset            = 0;
    engine->extension_component = (void*)exts;

    return TT_Err_Ok;
  }


  /* Finalize the extension component */

  LOCAL_FUNC
  TT_Error  TTExtend_Done( PEngine_Instance  engine )
  {
    FREE( engine->extension_component );
    return TT_Err_Ok;
  }


  /* Register a new extension */

  EXPORT_FUNC
  TT_Error  TT_Register_Extension( PEngine_Instance  engine,
                                   Long              id,
                                   Long              size,
                                   PExt_Constructor  create,
                                   PExt_Destructor   destroy )
  {
    PExtension_Registry  exts;
    PExtension_Class     clazz;
    Int                  p;


    exts = (PExtension_Registry)engine->extension_component;
    if ( !exts )
      return TT_Err_Ok;

    p = exts->num_extensions;

    if ( p >= TT_MAX_EXTENSIONS )
      return TT_Err_Too_Many_Extensions;

    
    clazz          = exts->classes + p;
    clazz->size    = size;
    clazz->build   = create;
    clazz->destroy = destroy;
    clazz->offset  = exts->cur_offset;

    exts->num_extensions++;
    exts->cur_offset += ( size + ALIGNMENT-1 ) & -ALIGNMENT;

    return TT_Err_Ok;
  }


  /* Query an extension block by extension_ID */

  EXPORT_FUNC
  TT_Error  TT_Extension_Get( PFace   face,
                              Long    extension_id,
                              void**  extension_block )
  {
    PExtension_Registry  registry;
    PExtension_Class     clazz;
    Int                  n;


    if ( !face->extension )
      return TT_Err_Extensions_Unsupported;

    registry = face->engine->extension_component;

    for ( n = 0; n < face->n_extensions; n++ )
    {
      clazz = registry->classes + n;
      if ( clazz->id == extension_id )
      {
        *extension_block = (PByte)face->extension + clazz->offset;
        return TT_Err_Ok;
      }
    }

    return TT_Err_Invalid_Extension_Id;
  }


  /* Destroy all extensions within a face object.  Called by the */
  /* face object destructor.                                     */

  LOCAL_FUNC
  TT_Error  Extension_Destroy( PFace  face )
  {
    PEngine_Instance     engine = face->engine;
    PExtension_Registry  registry;
    PExtension_Class     clazz;
    Int                  n;
    PByte                ext;


    registry = (PExtension_Registry)engine->extension_component;

    for ( n = 0; n < face->n_extensions; n++ )
    {
      clazz = registry->classes + n;
      ext   = (PByte)face->extension + clazz->offset;

      /* the destructor is optional */
      if ( clazz->destroy )
        clazz->destroy( (void*)ext, face );
    }

    /* destroy the face's extension block too */
    FREE( face->extension );
    face->n_extensions = 0;

    return TT_Err_Ok;
  }


  /* Create an extension within a face object.  Called by the */
  /* face object constructor.                                 */

  LOCAL_FUNC
  TT_Error  Extension_Create( PFace  face )
  {
    PEngine_Instance     engine = face->engine;
    PExtension_Registry  registry;
    PExtension_Class     clazz;
    TT_Error             error;
    Int                  n;
    PByte                ext;


    registry = (PExtension_Registry)engine->extension_component;

    face->n_extensions = registry->num_extensions;
    if ( ALLOC( face->extension, registry->cur_offset ) )
      return error;

    for ( n = 0; n < face->n_extensions; n++ )
    {
      clazz = registry->classes + n;
      ext   = (PByte)face->extension + clazz->offset;
      error = clazz->build( (void*)ext, face );
      if ( error )
        goto Fail;
    }
    return TT_Err_Ok;

  Fail:
    Extension_Destroy( face );
    return error;
  }


/* END */
