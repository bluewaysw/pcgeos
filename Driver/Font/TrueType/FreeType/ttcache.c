/*******************************************************************
 *
 *  ttcache.c                                                   1.1
 *
 *    Generic object cache
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
 * Changes between 1.1 and 1.0:
 *
 *  - introduced the refresher and finalizer in the cache class
 *    definition/implementation.
 *
 ******************************************************************/

#include "ttengine.h"
#include "ttmemory.h"
#include "ttcache.h"
#include "ttobjs.h"

/* required by the tracing mode */
#undef  TT_COMPONENT
#define TT_COMPONENT  trace_cache

#define ZERO_List( list )  list = NULL

/* The macro FREE_Elements aliases the current engine instance's */
/* free list_elements recycle list.                              */
#define FREE_Elements  ( engine->list_free_elements )


/*******************************************************************
 *
 *  Function    :  Element_New
 *
 *  Description :  Gets a new (either fresh or recycled) list
 *                 element.  The element is unlisted.
 *
 *  Input  :  None
 *
 *  Output :  List element address.  NULL if out of memory.
 *
 ******************************************************************/

  static
  PList_Element  Element_New( PEngine_Instance  engine )
  {
    PList_Element  element;


    if ( FREE_Elements )
    {
      element       = (PList_Element)FREE_Elements;
      FREE_Elements = element->next;
    }
    else
    {
      if ( !MEM_Alloc( element, sizeof ( TList_Element ) ) )
      {
        element->next = NULL;
        element->data = NULL;
      }
    }

    return element;
  }


/*******************************************************************
 *
 *  Function    :  Element_Done
 *
 *  Description :  Recycles an unlinked list element.
 *
 *  Input  :  The list element to recycle.  It _must_ be unlisted.
 *
 *  Output :  none.
 *
 *  Note   :  This function doesn't check the element.
 *
 ******************************************************************/

  static
  void  Element_Done( PEngine_Instance  engine,
                      PList_Element     element )
  {
    /* Simply add the list element to the recycle list */
    element->next = (PList_Element)FREE_Elements;
    FREE_Elements = element;
  }


/*******************************************************************
 *
 *  Function    :  Cache_Create
 *
 *  Description :  Creates a new cache that will be used to list
 *                 and recycle several objects of the same class.
 *
 *  Input  :  clazz       a pointer to the cache's class.  This is
 *                        a simple structure that describes the
 *                        the cache's object types and recycling
 *                        limits.
 *
 *            cache       address of cache to create
 *
 *  Output :  Error code.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Cache_Create( PEngine_Instance  engine,
                          PCache_Class      clazz,
                          TCache*           cache )
  {
    cache->engine     = engine;
    cache->clazz      = clazz;
    cache->idle_count = 0;

    ZERO_List( cache->active );
    ZERO_List( cache->idle );

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Cache_Destroy
 *
 *  Description :  Destroys a cache and all its idle and active
 *                 objects.  This will call each object's destructor
 *                 before freeing it.
 *
 *  Input  :  cache   address of cache to destroy
 *
 *  Output :  error code.
 *
 *  Note: This function is not MT-Safe, as we assume that a client
 *        isn't stupid enough to use an object while destroying it.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Cache_Destroy( TCache*  cache )
  {
    PDestructor    destroy;
    PList_Element  current;
    PList_Element  next;


    /* now destroy all active and idle listed objects */

    /* get the destructor function */
    destroy = cache->clazz->done;

    /* destroy all elements in active list */
    current = cache->active;
    while ( current )
    {
      next = current->next;
#ifdef __GEOS__
      ProcCallFixedOrMovable_cdecl( destroy, current->data );
#else
      destroy( current->data );
#endif  /* __GEOS__ */  
      FREE( current->data );

      Element_Done( cache->engine, current );
      current = next;
    }
    ZERO_List(cache->active);

    /* destroy all elements in idle list */
    current = cache->idle;
    while ( current )
    {
      next = current->next;
#ifdef __GEOS__
      ProcCallFixedOrMovable_cdecl( destroy, current->data );
#else
      destroy( current->data );
#endif
      FREE( current->data );

      Element_Done( cache->engine, current );
      current = next;
    }
    ZERO_List(cache->idle);

    cache->clazz      = NULL;
    cache->idle_count = 0;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  Cache_New
 *
 *  Description :  Extracts a new object from a cache.  This will
 *                 try to recycle an idle object, if any is found.
 *                 Otherwise, a new object will be allocated and
 *                 built (by calling its constructor).
 *
 *  Input  :   cache          address of cache to use
 *             new_object     address of target pointer to the 'new'
 *                            object
 *             parent_object  this pointer is passed to a new object
 *                            constructor (unused if object is
 *                            recycled)
 *
 *  Output :   Error code.
 *
 *  Notes: This function is thread-safe, each cache list is protected
 *         through the cache's mutex, if there is one...
 *
 *         *new_object will be set to NULL in case of failure.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Cache_New( TCache*  cache,
                       void**   new_object,
                       void*    parent_object )
  {
    TT_Error       error;
    PList_Element  current;
    PConstructor   build;
    PRefresher     reset;
    void*          object;


    current = cache->idle;
    if ( current )
    {
      cache->idle = current->next;
      cache->idle_count--;
    }

    if ( current )
    {
      object = current->data;
      reset  = cache->clazz->reset;
      if ( reset )
      {
#ifdef __GEOS__
        error = ProcCallFixedOrMovable_cdecl( reset, object, parent_object );
#else
        error = reset( object, parent_object );
#endif  /* __GEOS__ */
        if ( error )
        {
          current->next = cache->idle;
          cache->idle   = current;
          cache->idle_count++;
          goto Exit;
        }
      }
    }
    else
    {
      /* if no object was found in the cache, create a new one */
      build  = cache->clazz->init;

      if ( MEM_Alloc( object, cache->clazz->object_size ) )
        goto Memory_Fail;

      current = Element_New( cache->engine );
      if ( !current )
        goto Memory_Fail;

      current->data = object;

#ifdef __GEOS__
      error = ProcCallFixedOrMovable_cdecl( build, object, parent_object );
#else
      error = build( object, parent_object );
#endif    /* __GEOS__ */
      if ( error )
      {
        Element_Done( cache->engine, current );
        goto Fail;
      }
    }

    current->next = cache->active;
    cache->active = current;

    *new_object = current->data;
    return TT_Err_Ok;

  Exit:
    *new_object = NULL;
    return  error;

  Memory_Fail:
    error = TT_Err_Out_Of_Memory;

  Fail:
    FREE( object );
    goto Exit;
  }


/*******************************************************************
 *
 *  Function    :  Cache_Done
 *
 *  Description :  Releases an object to the cache.  This will either
 *                 recycle or destroy the object, based on the cache's
 *                 class and state.
 *
 *  Input  :  cache   the cache to use
 *            data    the object to recycle/discard
 *
 *  Output :  error code.
 *
 *  Notes  :  The object's destructor is called only when
 *            the objectwill be effectively destroyed by this
 *            function.  This will not happen during recycling.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  Cache_Done( TCache*  cache, void*  data )
  {
    TT_Error       error;
    PList_Element  element;
    PList_Element  prev;
    PFinalizer     finalize;
    Short          limit;
    Bool           destroy;


    element = cache->active;
    prev = NULL;
    while ( element )
    {
      if ( element->data == data )
      {
        if ( prev )
          prev->next = element->next;
        else
          cache->active = element->next;
        goto Suite;
      }
      prev = element;
      element = element->next;
    }

    return TT_Err_Unlisted_Object;

  Suite:

    limit   = cache->clazz->idle_limit;
    destroy = (cache->idle_count >= limit);

    if ( destroy )
    {
      /* destroy the object when the cache is full */
#ifdef __GEOS__
      ProcCallFixedOrMovable_cdecl( cache->clazz->done, element->data );
#else
      cache->clazz->done( element->data );
#endif  /* __GEOS__ */
      FREE( element->data );
      Element_Done( cache->engine, element );
    }
    else
    {
      /* Finalize the object before adding it to the   */
      /* idle list.  Return the error if any is found. */

      finalize = cache->clazz->finalize;
      if ( finalize )
      {
#ifdef __GEOS__
        error = ProcCallFixedOrMovable_cdecl( finalize, element->data );
#else
        error = finalize( element->data );
#endif  /* __GEOS__ */
        if ( error )
          goto Exit;

        /* Note: a failure at finalize time is a severe bug in     */
        /*       the engine, which is why we allow ourselves to    */
        /*       lose the object in this case.  A finalizer should */
        /*       have its own error codes to spot this kind of     */
        /*       problems easily.                                  */
      }

      element->next = cache->idle;
      cache->idle   = element;
      cache->idle_count++;
    }

    error = TT_Err_Ok;

  Exit:
    return error;
  }


  LOCAL_FUNC
  TT_Error  TTCache_Init( PEngine_Instance  engine )
  {
    /* Create list elements mutex */
    FREE_Elements = NULL;
    return TT_Err_Ok;
  }


  LOCAL_FUNC
  TT_Error  TTCache_Done( PEngine_Instance  engine )
  {
    /* We don't protect this function, as this is the end of the engine's */
    /* execution..                                                        */
    PList_Element  element, next;


    /* frees the recycled list elements */
    element = FREE_Elements;
    while ( element )
    {
      next = element->next;
      FREE( element );
      element = next;
    }
    return TT_Err_Ok;
  }


/* END */
