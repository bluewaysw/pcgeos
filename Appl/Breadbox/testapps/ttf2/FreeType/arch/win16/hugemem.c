/*******************************************************************
 *
 *  hugemem.c
 *
 *    Memory management component (body)
 *    for dealing with "huge" objects with 16-bit Windows.
 *
 *  Written by Antoine Leca based on ideas from Dave Hoo.
 *  Copyright 1999 by Dave Hoo, Antoine Leca,
 *  David Turner, Robert Wilhelm, and Werner Lemberg.
 *
 *  This file is part of the FreeType project, and may only be used
 *  modified and distributed under the terms of the FreeType project
 *  license, LICENSE.TXT.  By continuing to use, modify, or distribute
 *  this file you indicate that you have read the license and
 *  understand and accept it fully.
 *
 ******************************************************************/

#include <limits.h>
#include <windows.h>

#include "ttdebug.h"
#include "ttmemory.h"
#include "ttengine.h"

#ifndef TT_HUGE_PTR
#error  "This component needs TT_HUGE_PTR to be #defined."
#endif

#ifdef  TT_CONFIG_OPTION_THREAD_SAFE
#error  "This component needs static allocation and is not re-entrant."
#endif

  /* If the memory reclaimed is abobve this limit, alloc directly from */
  /* global heap. Else, alloc using malloc (using suballocation).      */
#ifndef MEMORY_MIN_GLOBAL
#define MEMORY_MIN_GLOBAL   4096
#endif

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

  static Int  fail_alloc;
  static Int  fail_realloc;
  static Int  fail_free;

#else

  /* We need a tracing stack of the calls to big chunks of memory,   */
  /* in order to call the matching version of free().                */

#define MAX_TRACKED_BIGCHUNKS    64

  struct  TMemRec_
  {
    void*  base;
  };

  typedef struct TMemRec_  TMemRec;

  static TMemRec  pointers[MAX_TRACKED_BIGCHUNKS + 1];

#endif /* DEBUG_MEMORY */


#ifndef TT_CONFIG_REENTRANT
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
    Int  i;


    if ( !P )
      return TT_Err_Invalid_Argument;
        /* Also see below for another case of "invalid argument". */

    if ( Size > 0 )
    {
      if ( Size >= MEMORY_MIN_GLOBAL )
      {
        HANDLE  hMem;

        hMem = GlobalAlloc( GMEM_ZEROINIT, Size );
        if ( !hMem )
          return TT_Err_Out_Of_Memory;

        *P = (void*)GlobalLock( hMem );
      }
      else
        *P = (void*)malloc( Size );

      if ( !*P )
        return TT_Err_Out_Of_Memory;

#ifndef TT_CONFIG_REENTRANT
      TTMemory_MaxAllocated += Size;
      TTMemory_Allocated    += Size;
#endif

#ifdef DEBUG_MEMORY

      num_alloc++;

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

#else

      if ( Size >= MEMORY_MIN_GLOBAL )
      {
        i = 0;
        while ( i < MAX_TRACKED_BIGCHUNKS && pointers[i].base != NULL )
          i++;

        if ( i >= MAX_TRACKED_BIGCHUNKS )
          /* We fail badly here. Increase MAX_TRACKED_BIGCHUNKS if needed. */
          return TT_Err_Invalid_Argument;
        else
          pointers[i].base = *P;
      }

#endif /* DEBUG_MEMORY */

      /* The nice thing about GlobalAlloc is that it zeroes the memory. */

      if ( Size < MEMORY_MIN_GLOBAL )
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
    ULong   oldSize;
    void*   Q;
    Int  i;


    if ( !P )
      return TT_Err_Invalid_Argument;

    if ( !*P )
      return TT_Alloc( Size, P );

    if ( Size == 0 )
      return TT_Free( P );

#ifdef DEBUG_MEMORY

    num_realloc++;

    i = 0;
    while ( i < MAX_TRACKED_BLOCKS && pointers[i].base != *P )
      i++;

    if ( i >= MAX_TRACKED_BLOCKS )
      fail_realloc++;
    else
      oldSize = pointers[i].size;

#else

    i = 0;
    while ( i < MAX_TRACKED_BIGCHUNKS && pointers[i].base != *P )
      i++;

    /* If we did not found the pointer, then this is a "small" chunk. */

    if ( i < MAX_TRACKED_BIGCHUNKS )
    {
        /* Signal we found a big one. Real size does not matter. */
      oldSize = MEMORY_MIN_GLOBAL;
    }

#endif /* DEBUG_MEMORY */

    if ( oldSize >= MEMORY_MIN_GLOBAL )
    {
      /* Deal with a big chunk. */
      HANDLE hMem, hNewMem;

      hMem = GlobalHandle ( (ULong)*P >> 16 ) & 0xFFFF;
      if ( !hMem )  /* Bad call... */
        return TT_Err_Invalid_Argument;

      GlobalUnlock( hMem );
	  hNewMem = GlobalReAlloc( hMem, Size, 0 );
      if ( hNewMem )
        *P = (void*)GlobalLock( hNewMem );
    }
    if ( Size >= MEMORY_MIN_GLOBAL )
    {
      /* A small chunk crosses the limit... */

      if( TT_Alloc( Size, &Q ) != TT_Err_Ok )
        Q = NULL;  /* Failed to create the new block. */
      else
        MEM_Copy( Q, *P, oldSize );

          /* We need to register the new entry. */
#ifndef DEBUG_MEMORY

      i = 0;
      while ( i < MAX_TRACKED_BIGCHUNKS && pointers[i].base != NULL )
        i++;

      if ( i >= MAX_TRACKED_BIGCHUNKS )
        /* We fail badly here. Increase MAX_TRACKED_BIGCHUNKS if needed. */
        return TT_Err_Invalid_Argument;
#endif /* DEBUG_MEMORY */
    }
    else
      Q = (void*)realloc( *P, Size );

    if ( !Q )
    {
      TT_Free( *P );
      return TT_Err_Out_Of_Memory;
    }

#ifdef DEBUG_MEMORY

    if ( i < MAX_TRACKED_BLOCKS )
    {
#ifndef TT_CONFIG_REENTRANT
      TTMemory_Allocated += Size - pointers[i].size;
      if ( Size > pointers[i].size )
        TTMemory_MaxAllocated += Size - pointers[i].size;
#endif

      pointers[i].base = Q;
      pointers[i].size = Size;
    }
#else
    if ( i < MAX_TRACKED_BIGCHUNKS )
    {
      pointers[i].base = Q;
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
    Int  i;
    Long Size = 0;


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
#ifndef TT_CONFIG_REENTRANT
      TTMemory_Allocated -= pointers[i].size;
#endif

      Size = pointers[i].size;
      pointers[i].base = NULL;
      pointers[i].size = 0;
    }

#else

    i = 0;
    while ( i < MAX_TRACKED_BIGCHUNKS && pointers[i].base != *P )
      i++;

    /* If we did not found the pointer, then this is a "small" chunk. */

    if ( i < MAX_TRACKED_BIGCHUNKS )
    {
      pointers[i].base = NULL;
        /* Signal we found a big one. Real size does not matter. */
      Size = MEMORY_MIN_GLOBAL;
    }

#endif /* DEBUG_MEMORY */

    if ( Size >= MEMORY_MIN_GLOBAL )
    {
      HANDLE hMem;

      hMem = GlobalHandle ( (ULong)*P >> 16 ) & 0xFFFF;
      if ( !hMem )  /* Bad call... */
        return TT_Err_Invalid_Argument;

      GlobalUnlock( hMem );
      GlobalFree  ( hMem );
    }
    else
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

    fail_alloc   = 0;
    fail_realloc = 0;
    fail_free    = 0;
#else
    Int  i;

    for ( i = 0; i < MAX_TRACKED_BIGCHUNKS; i++ )
    {
      pointers[i].base = NULL;
    }
#endif


#ifndef TT_CONFIG_REENTRANT
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

    if ( num_leaked > 0 )
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
      fprintf( stderr, "No memory leaks !\n" );

#endif /* DEBUG_MEMORY */

    return TT_Err_Ok;
  }


/* END */
