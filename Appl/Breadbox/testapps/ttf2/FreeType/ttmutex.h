/*******************************************************************
 *
 *  ttmutex.h                                                1.0
 *
 *    Mutual exclusion object / dummy generic interface.
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
 *  Note:  This file provides a generic interface.  The implementation
 *         to compile depends on your system and the type of
 *         library you want to build (either singly-threaded,
 *         thread-safe or re-entrant).
 *
 *         Please read the technical documentation for more details.
 *
 ******************************************************************/

#ifndef TTMUTEX_H
#define TTMUTEX_H

#include "ttconfig.h"


  typedef  void*  TMutex;  /* typeless reference to a mutex */

#ifdef TT_CONFIG_OPTION_THREAD_SAFE /* thread-safe and re-entrant builds */

#define MUTEX_Create( mutex )   TT_Mutex_Create ( &(mutex) )
#define MUTEX_Destroy( mutex )  TT_Mutex_Delete ( &(mutex) )
#define MUTEX_Lock( mutex )     TT_Mutex_Lock   ( &(mutex) )
#define MUTEX_Release( mutex )  TT_Mutex_Release( &(mutex) )

  LOCAL_DEF void  TT_Mutex_Create ( TMutex*  mutex ); /* Create a new mutex */
  LOCAL_DEF void  TT_Mutex_Delete ( TMutex*  mutex ); /* Delete a mutex     */
  LOCAL_DEF void  TT_Mutex_Lock   ( TMutex*  mutex ); /* Lock a mutex.      */
  LOCAL_DEF void  TT_Mutex_Release( TMutex*  mutex ); /* Release a mutex    */

#else  /* for the single-thread build */

#define MUTEX_Create( mutex )   /* nothing */
#define MUTEX_Destroy( mutex )  /* nothing */
#define MUTEX_Lock( mutex )     /* nothing */
#define MUTEX_Release( mutex )  /* nothing */

  /* No code will be generated for mutex operations */

#endif /* TT_CONFIG_OPTION_THREAD_SAFE */

#endif /* TTMUTEX_H */


/* END */
