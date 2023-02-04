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
 ******************************************************************/

#include "ttmemory.h"
#include "ttengine.h"
#include <geode.h>
#include <lmem.h>
#include <ec.h>

/* required by the tracing mode */
#undef  TT_COMPONENT
#define TT_COMPONENT  trace_memory


#ifndef TT_CONFIG_OPTION_THREAD_SAFE
  Long  TTMemory_Allocated;
  Long  TTMemory_MaxAllocated;
#endif


#define MAX_BLOCK_SIZE  32000
#define MAX_LMEM_BLOCKS 32

/* Block for small allocs */
MemHandle lmem;

ChunkHandle   lmemBlock[MAX_LMEM_BLOCKS];
void*         ptrToBlock[MAX_LMEM_BLOCKS];


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
    MemHandle  handle;


    if ( !P )
      return TT_Err_Invalid_Argument;

    if ( Size > MAX_BLOCK_SIZE )
    {
      EC_ERROR( 100 );
      return TT_Err_Out_Of_Memory;
    }

    if ( Size > 0 )
    {
      handle = MemAllocSetOwner( GeodeGetCodeProcessHandle(), 
                                 Size,
                                 HF_SHARABLE | HF_SWAPABLE, 
                                 HAF_ZERO_INIT | HAF_LOCK );
      if ( !handle )
        return TT_Err_Out_Of_Memory;
      
      *P     = MemDeref( handle );
    }
    else
      *P = NULL;

    return TT_Err_Ok;
  }


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
    if ( !P || !*P )
      return TT_Err_Ok;

    MemFree( MemPtrToHandle( *P ) );

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
   /* lmem = MemAllocSetOwner(GeodeGetCodeProcessHandle(), 
                            10 * 1024,
                            HF_SHARABLE | HF_SWAPABLE, 
                            HAF_ZERO_INIT | HAF_NO_ERR | HAF_LOCK );
    
    LMemInitHeap(block, LMEM_TYPE_GENERAL, 
                     LMF_NO_HANDLES | LMF_NO_ENLARGE | LMF_RETURN_ERRORS, 
                     sizeof(LMemBlockHeader), 0, 
		     newSize - sizeof(LMemBlockHeader));*/

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
    //MemFree( lmem );

    return TT_Err_Ok;
  }


/* END */
