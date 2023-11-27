/*******************************************************************
 *
 *  ttcache.h                                                   1.1
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
 *
 *  This component defines and implements object caches.
 *
 *  An object class is a structure layout that encapsulate one
 *  given type of data used by the FreeType engine.  Each object
 *  class is completely described by:
 *
 *    - a 'root' or 'leading' structure containing the first
 *      important fields of the class.  The root structure is
 *      always of fixed size.
 *
 *      It is implemented as a simple C structure, and may
 *      contain several pointers to sub-tables that can be
 *      sized and allocated dynamically.
 *
 *      Examples:  TFace, TInstance, TGlyph & TExecution_Context
 *                 (defined in 'ttobjs.h')
 *
 *    - we make a difference between 'child' pointers and 'peer'
 *      pointers.  A 'child' pointer points to a sub-table that is
 *      owned by the object, while a 'peer' pointer points to any
 *      other kind of data the object isn't responsible for.
 *
 *      An object class is thus usually a 'tree' of 'child' tables.
 *
 *    - each object class needs a constructor and a destructor.
 *
 *      A constructor is a function which receives the address of
 *      freshly allocated and zeroed object root structure and
 *      'builds' all the valid child data that must be associated
 *      to the object before it becomes 'valid'.
 *
 *      A destructor does the inverse job: given the address of
 *      a valid object, it must discard all its child data and
 *      zero its main fields (essentially the pointers and array
 *      sizes found in the root fields).
 *
 *
 *  Important notes:
 *
 *      When the constructor fails to allocate an object, it must
 *      return immediately with an error code, and not try to release
 *      what it has previously allocated before the error.  The cache
 *      manager detects the error and calls the destructor on the
 *      partial object, before returning the error to the caller (along
 *      with a NULL pointer for the "new" object).
 *
 *      The destructor must thus be able to deal with "partial objects",
 *      i.e., objects where only part of the child tables are allocated,
 *      and only release these ones.  As the TT_Free() function accepts
 *      a NULL parameter (and returns successfuly in this case), no check
 *      is really necessary when using the macro 'FREE()'.
 *
 *      Currently, there is no check in the cache manager to see if a
 *      destructor fails (double error state!).
 *
 *      This scheme is more compact and more maintanable than the one
 *      where de-allocation code is duplicated in the constructor
 *      _and_ the destructor.
 *
 *
 *
 * Changes between 1.1 and 1.0:
 *
 *  - introduced the refreshed and finalizer class definition/implementation
 *  - inserted an engine instance pointer in the cache structure
 *
 ******************************************************************/

#ifndef TTCACHE_H
#define TTCACHE_H

#include "tttypes.h"
#include "ttconfig.h"
#include "ttmutex.h"

#ifdef __cplusplus
  extern "C" {
#endif

  typedef TT_Error  TConstructor( void*  object,
                                  void*  parent );

  typedef TT_Error  TDestructor ( void*  object );

  typedef TConstructor  TRefresher;
  typedef TDestructor   TFinalizer;

  typedef TConstructor*  PConstructor;
  typedef TDestructor*   PDestructor;
  typedef TRefresher*    PRefresher;
  typedef TFinalizer*    PFinalizer;


  /* A Cache class record holds the data necessary to define */
  /* a cache kind.                                           */
  struct  TCache_Class_
  {
    ULong         object_size;
    Long          idle_limit;
    PConstructor  init;
    PDestructor   done;
    PRefresher    reset;
    PFinalizer    finalize;
  };

  typedef struct TCache_Class_  TCache_Class;
  typedef TCache_Class*         PCache_Class;



  /* Simple list node record.  A list element is said to be 'unlinked' */
  /* when it doesn't belong to any list.                               */
  struct  TList_Element_;

  typedef struct TList_Element_  TList_Element;
  typedef TList_Element*         PList_Element;

  struct  TList_Element_
  {
    PList_Element  next;
    void*          data;
  };


  /* Simple singly-linked list record - LIFO style, no tail field */
  typedef PList_Element  TSingle_List;

  struct  TCache_
  {
    PEngine_Instance  engine;
    PCache_Class      clazz;      /* 'class' is a reserved word in C++ */
    TMutex*           lock;
    TSingle_List      active;
    TSingle_List      idle;
    Long              idle_count;
  };

  typedef struct TCache_  TCache;
  typedef TCache*         PCache;

  /* Returns a new list element, either fresh or recycled. */
  /* Note: the returned element is unlinked.               */

  /* An object cache holds two lists tracking the active and */
  /* idle objects that are currently created and used by the */
  /* engine.  It can also be 'protected' by a mutex.         */

  /* Initializes a new cache, of class 'clazz', pointed by 'cache', */
  /* protected by the 'lock' mutex. Set 'lock' to NULL if the cache */
  /* doesn't need protection                                        */

  LOCAL_DEF
  TT_Error  Cache_Create( PEngine_Instance  engine,
                          PCache_Class      clazz,
                          TCache*           cache,
                          TMutex*           lock );

  /* Destroys a cache and all its listed objects */

  LOCAL_DEF
  TT_Error  Cache_Destroy( TCache*  cache );


  /* Extracts a new object from the cache */

  LOCAL_DEF
  TT_Error Cache_New( TCache*  cache,
                      void**   new_object,
                      void*    parent_object );


  /* Returns an object to the cache, or discards it depending */
  /* on the cache class' 'idle_limit' field                   */

  LOCAL_DEF
  TT_Error  Cache_Done( TCache*  cache, void*  data );

#define CACHE_New( _cache, _newobj, _parent ) \
          Cache_New( (TCache*)_cache, (void**)&_newobj, (void*)_parent )

#define CACHE_Done( _cache, _obj ) \
          Cache_Done( (TCache*)_cache, (void*)_obj )



  LOCAL_DEF
  TT_Error  TTCache_Init( PEngine_Instance  engine );

  LOCAL_DEF
  TT_Error  TTCache_Done( PEngine_Instance  engine );


#ifdef __cplusplus
  }
#endif

#endif /* TTCACHE_H */


/* END */
