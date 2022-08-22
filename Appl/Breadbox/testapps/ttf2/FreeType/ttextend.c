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
  typedef ChunkHandle                  CExtension_Registry;

  #define EXTENSION_ELEMENT( _ext_element_ )  \
    ELEMENT( PExtension_Registry, registry, _ext_element_ )


  /* Initialize the extension component */

  LOCAL_FUNC
  TT_Error  TTExtend_Init( TT_Engine  engine )
  {
    TT_Error             error;
    CExtension_Registry  registry;
    

    CHECK_CHUNK( engine );

    if ( GALLOC( registry, sizeof ( TExtension_Registry ) ) )
      return error;
    
    CHECK_CHUNK( registry );

    EXTENSION_ELEMENT( num_extensions )   = 0;
    EXTENSION_ELEMENT( cur_offset )       = 0;
    ENGINE_ELEMENT( extension_component ) = registry;

    return TT_Err_Ok;
  }


  /* Finalize the extension component */

  LOCAL_FUNC
  TT_Error  TTExtend_Done( TT_Engine  engine )
  {
    CHECK_CHUNK( engine );

    GFREE( ENGINE_ELEMENT( extension_component ) );
    return TT_Err_Ok;
  }


  /* Register a new extension */

  EXPORT_FUNC
  TT_Error  TT_Register_Extension( TT_Engine         engine,
                                   Long              id,
                                   Long              size,
                                   PExt_Constructor  create,
                                   PExt_Destructor   destroy )
  {
    CExtension_Registry  registry;
    PExtension_Class     clazz;
    Int                  p;


    CHECK_CHUNK( engine );

    registry = (CExtension_Registry)ENGINE_ELEMENT( extension_component );
    if ( !registry )
      return TT_Err_Ok;

    p = EXTENSION_ELEMENT( num_extensions );

    if ( p >= TT_MAX_EXTENSIONS )
      return TT_Err_Too_Many_Extensions;

    
    clazz          = EXTENSION_ELEMENT( classes + p );
    clazz->id      = id;
    clazz->size    = size;
    clazz->build   = create;
    clazz->destroy = destroy;
    clazz->offset  = EXTENSION_ELEMENT( cur_offset );

    EXTENSION_ELEMENT( num_extensions++ );
    EXTENSION_ELEMENT( cur_offset ) += ( size + ALIGNMENT-1 ) & -ALIGNMENT;

    return TT_Err_Ok;
  }


  /* Query an extension block by extension_ID */

  EXPORT_FUNC
  TT_Error  TT_Extension_Get( PFace   face,
                              Long    extension_id,
                              void**  extension_block )
  {
    TT_Engine            engine = face->engine;
    CExtension_Registry  registry;
    PExtension_Class     clazz;
    Int                  n;


    if ( !face->extension )
      return TT_Err_Extensions_Unsupported;

    registry = ENGINE_ELEMENT( extension_component );

    for ( n = 0; n < face->n_extensions; n++ )
    {
      clazz = EXTENSION_ELEMENT( classes + n );
      if ( clazz->id == extension_id )
      {
        *extension_block = (PByte)DEREF( face->extension ) + clazz->offset;
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
    TT_Engine            engine = face->engine;
    CExtension_Registry  registry;
    PExtension_Class     clazz;
    Int                  n;
    PByte                ext;


    registry = (PExtension_Registry)ENGINE_ELEMENT( extension_component );

    for ( n = 0; n < face->n_extensions; n++ )
    {
      clazz = EXTENSION_ELEMENT( classes + n );
      ext   = (PByte)DEREF( face->extension ) + clazz->offset;

      /* the destructor is optional */
      if ( clazz->destroy )
        clazz->destroy( (void*)ext, face );
    }

    /* destroy the face's extension block too */
    GFREE( face->extension );
    face->n_extensions = 0;

    return TT_Err_Ok;
  }


  /* Create an extension within a face object.  Called by the */
  /* face object constructor.                                 */

  LOCAL_FUNC
  TT_Error  Extension_Create( PFace  face )
  {
    TT_Engine            engine = face->engine;
    CExtension_Registry  registry;
    PExtension_Class     clazz;
    TT_Error             error;
    Int                  n;
    PByte                ext;


    registry = (CExtension_Registry)ENGINE_ELEMENT( extension_component );

    face->n_extensions = EXTENSION_ELEMENT( num_extensions );
    if ( GALLOC( face->extension, EXTENSION_ELEMENT( cur_offset ) ) )
      return error;

    for ( n = 0; n < face->n_extensions; n++ )
    {
      clazz = EXTENSION_ELEMENT( classes + n );
      ext   = (PByte)DEREF( face->extension ) + clazz->offset;
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
