/*******************************************************************
 *
 *  ttmutex.c                                                1.0
 *
 *    Mutual exclusion object, single-threaded implementation
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
 *  NOTE:  This is a generic non-functional implementation
 *         that you are welcome to refine for your own system.
 *
 *         Please name your system-specific source with a
 *         different name (like ttmutex-os2.c or ttmutex-linux.c)
 *         and change your makefile accordingly.
 *
 ******************************************************************/

#include "ttmutex.h"


/* required by the tracing mode */
#undef  TT_COMPONENT
#define TT_COMPONENT  trace_mutex


/* ANSI C prevents the compilation of empty units.  We thus introduce */
/* a dummy typedef to get rid of compiler warnings/errors.            */
/* Note that gcc's -ansi -pedantic does not report any error here.    */
/* Watcom, VC++ or Borland C++ do however.                            */

  typedef void  _ttmutex_to_satisfy_ANSI_C_;


#ifdef TT_CONFIG_OPTION_THREAD_SAFE

  LOCAL_FUNC
  void  TT_Mutex_Create ( TMutex*  mutex )
  {
    *mutex = (void*)-1;
    /* Replace this line with your own mutex creation code */
  }


  LOCAL_FUNC
  void  TT_Mutex_Delete ( TMutex*  mutex )
  {
    *mutex = (void*)0;
    /* Replace this line with your own mutex destruction code */
  }


  LOCAL_FUNC
  void  TT_Mutex_Lock   ( TMutex*  mutex )
  {
    /* NOTE: It is legal to call this function with a NULL argument */
    /*       in which case an immediate return is appropriate.      */
    if ( !mutex )
      return;

    ; /* Insert your own mutex locking code here */
  }


  LOCAL_FUNC
  void  TT_Mutex_Release( TMutex*  mutex )
  {
    /* NOTE: It is legal to call this function with a NULL argument */
    /*       in which case an immediate return is appropriate       */
    if ( !mutex )
      return;

    ; /* Insert your own mutex release code here */
  }

#endif /* TT_CONFIG_OPTION_THREAD_SAFE */


/* END */
