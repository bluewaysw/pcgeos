/*******************************************************************
 *
 *  ttmemory.c                                               1.2
 *
 *    Memory management component (body).
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
 *  Changes between 1.1 and 1.2:
 *
 *  - the font pool is gone.
 *
 *  - introduced the FREE macro and the Free function for
 *    future use in destructors.
 *
 *  - Init_FontPool() is now a macro to allow the compilation of
 *    'legacy' applications (all four test programs have been updated).
 *
 ******************************************************************/

#include "ttdebug.h"
#include "ttmemory.h"
#include "ttengine.h"

/* required by the tracing mode */
#undef  TT_COMPONENT
#define TT_COMPONENT  trace_memory


#ifdef DEBUG_MEMORY

#include <stdio.h>

#define MAX_TRACKED_BLOCKS  1024

  struct  TMemRec_
  {
    void*  base;
    Long   size;
  };

  typedef struct TMemRec_  TMemRec;

  static TMemRec  pointers[MAX_TRACKED_BLOCKS + 1];

  static Int  num_alloc;
  static Int  num_free;
  static Int  num_realloc; /* counts only `real' reallocations
                              (i.e., an existing buffer will be resized
                              to a value larger than zero */
  static unsigned int  allocated;
  static unsigned int  max_allocated;
  static unsigned int  max_blocksize;
  static unsigned int  num_blocks;
  static unsigned int  max_num_blocks;

  static Int  fail_alloc;
  static Int  fail_realloc;
  static Int  fail_free;

#endif /* DEBUG_MEMORY */


#ifndef TT_CONFIG_OPTION_THREAD_SAFE
  Long  TTMemory_Allocated;
  Long  TTMemory_MaxAllocated;
#endif


/*******************************************************************
 *
 *  Function    :  TT_Alloc
 *
 *  Description :  Allocates memory from the heap buffer.
 *
 *  Input  :  Size      size of the memory to be allocated
 *            P         pointer to a buffer pointer
 *
 *  Output :  Error code.
 *
 *  NOTE :  The newly allocated block should _always_ be zeroed
 *          on return.  Many parts of the engine rely on this to
 *          work properly.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Alloc( ULong  Size, void**  P )
  {
#ifdef DEBUG_MEMORY
    Int  i;
#endif


    if ( !P )
      return TT_Err_Invalid_Argument;

    if ( Size > (size_t)-1 )
      return TT_Err_Out_Of_Memory;
    if ( Size > 0 )
    {
      *P = (void*)malloc( Size );
      if ( !*P )
        return TT_Err_Out_Of_Memory;

#ifndef TT_CONFIG_OPTION_THREAD_SAFE
      TTMemory_Allocated    += Size;
      TTMemory_MaxAllocated += Size;
#endif

#ifdef DEBUG_MEMORY

      num_alloc++;
      num_blocks++;
      allocated += Size;
      if( num_blocks > max_num_blocks )
        max_num_blocks = num_alloc;
      if( allocated > max_allocated )
        max_allocated = allocated;
      if( Size > max_blocksize )
        max_blocksize = Size;

      i = 0;
      while ( i < MAX_TRACKED_BLOCKS && pointers[i].base != NULL )
        i++;

      if ( i >= MAX_TRACKED_BLOCKS )
        fail_alloc++;
      else
      {
        pointers[i].base = *P;
        pointers[i].size = Size;
      }

#endif /* DEBUG_MEMORY */

      MEM_Set( *P, 0, Size );
    }
    else
      *P = NULL;

    return TT_Err_Ok;
  }


#ifdef TT_CONFIG_OPTION_EXTEND_ENGINE


/*******************************************************************
 *
 *  Function    :  TT_Realloc
 *
 *  Description :  Reallocates memory from the heap buffer.
 *
 *  Input  :  Size      new size of the memory to be allocated;
 *                      if zero, TT_Free() will be called
 *            P         pointer to a buffer pointer; if *P == NULL,
 *                      TT_Alloc() will be called
 *
 *  Output :  Error code.
 *
 *  NOTES :  It's not necessary to zero the memory in case the 
 *           reallocated buffer is larger than before -- the
 *           application has to take care of this.
 *
 *           If the memory request fails, TT_Free() will be
 *           called on *P, and TT_Err_Out_Of_Memory returned.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Realloc( ULong  Size, void**  P )
  {
    void*  Q;

#ifdef DEBUG_MEMORY
    Int  i;
#endif


    if ( !P )
      return TT_Err_Invalid_Argument;

    if ( !*P )
      return TT_Alloc( Size, P );

    if ( Size == 0 )
      return TT_Free( P );

    if ( Size > (size_t)-1 )
    {
      TT_Free( *P );
      return TT_Err_Out_Of_Memory;
    }

    Q = (void*)realloc( *P, Size );
    if ( !Q )
    {
      TT_Free( *P );
      return TT_Err_Out_Of_Memory;
    }

#ifdef DEBUG_MEMORY

    num_realloc++;

    i = 0;
    while ( i < MAX_TRACKED_BLOCKS && pointers[i].base != *P )
      i++;

    if ( i >= MAX_TRACKED_BLOCKS )
      fail_realloc++;
    else
    {
      allocated += Size - pointers[i].size;
      if( allocated > max_allocated )
        max_allocated = allocated;
      if( Size > max_blocksize )
        max_blocksize = Size;


#ifndef TT_CONFIG_OPTION_THREAD_SAFE
      TTMemory_Allocated += Size - pointers[i].size;
      if ( Size > pointers[i].size )
        TTMemory_MaxAllocated += Size - pointers[i].size;
#endif

      pointers[i].base = Q;
      pointers[i].size = Size;
    }
#endif /* DEBUG_MEMORY */

    *P = Q;

    return TT_Err_Ok;
  }


#endif /* TT_CONFIG_OPTION_EXTEND_ENGINE */


/*******************************************************************
 *
 *  Function    :  TT_Free
 *
 *  Description :  Releases a previously allocated block of memory.
 *
 *  Input  :  P    pointer to memory block
 *
 *  Output :  Always SUCCESS.
 *
 *  Note : The pointer must _always_ be set to NULL by this function.
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Free( void**  P )
  {
#ifdef DEBUG_MEMORY
    Int  i;
#endif /* DEBUG_MEMORY */


    if ( !P || !*P )
      return TT_Err_Ok;

#ifdef DEBUG_MEMORY

    num_free++;

    i = 0;
    while ( i < MAX_TRACKED_BLOCKS && pointers[i].base != *P )
      i++;

    if ( i >= MAX_TRACKED_BLOCKS )
      fail_free++;
    else
    {
        allocated -= pointers[i].size;
        num_blocks--;


#ifndef TT_CONFIG_OPTION_THREAD_SAFE
      TTMemory_Allocated -= pointers[i].size;
#endif

      pointers[i].base = NULL;
      pointers[i].size = 0;
    }
#endif /* DEBUG_MEMORY */

    free( *P );

    *P = NULL;

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  TTMemory_Init
 *
 *  Description :  Initializes the memory.
 *
 *  Output :  Always SUCCESS.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  TTMemory_Init( void )
  {
#ifdef DEBUG_MEMORY
    Int  i;


    for ( i = 0; i < MAX_TRACKED_BLOCKS; i++ )
    {
      pointers[i].base = NULL;
      pointers[i].size = 0;
    }

    num_alloc   = 0;
    num_realloc = 0;
    num_free    = 0;

    allocated     = 0;
    max_allocated = 0;
    num_blocks    = 0;
    max_num_blocks = 0;

    fail_alloc   = 0;
    fail_realloc = 0;
    fail_free    = 0;
#endif


#ifndef TT_CONFIG_OPTION_THREAD_SAFE
    TTMemory_Allocated    = 0;
    TTMemory_MaxAllocated = 0;
#endif

    return TT_Err_Ok;
  }


/*******************************************************************
 *
 *  Function    :  TTMemory_Done
 *
 *  Description :  Finalizes memory usage.
 *
 *  Output :  Always SUCCESS.
 *
 ******************************************************************/

  LOCAL_FUNC
  TT_Error  TTMemory_Done( void )
  {
#ifdef DEBUG_MEMORY
    Int  i, num_leaked, tot_leaked;


    num_leaked = 0;
    tot_leaked = 0;

    for ( i = 0; i < MAX_TRACKED_BLOCKS; i++ )
    {
      if ( pointers[i].base )
      {
        num_leaked ++;
        tot_leaked += pointers[i].size;
      }
    }
/*
    fprintf( stderr,
             "%d memory allocations, of which %d failed\n",
             num_alloc,
             fail_alloc );

    fprintf( stderr,
             "%d memory reallocations, of which %d failed\n",
             num_realloc,
             fail_realloc );

    fprintf( stderr,
             "%d memory frees, of which %d failed\n",
             num_free,
             fail_free );
*/
/*    if ( num_leaked > 0 )
    {
      fprintf( stderr,
               "There are %d leaked memory blocks, totalizing %d bytes\n",
               num_leaked, tot_leaked );

      for ( i = 0; i < MAX_TRACKED_BLOCKS; i++ )
      {
        if ( pointers[i].base )
        {
          fprintf( stderr,
                   "index: %4d (base: $%08lx, size: %08ld)\n",
                   i,
                   (long)pointers[i].base,
                   pointers[i].size );
        }
      }
    }
    else
      fprintf( stderr, "No memory leaks !\n" ); */

#endif /* DEBUG_MEMORY */

    return TT_Err_Ok;
  }


/* END */
