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
#include "ttadapter.h"
#include <geode.h>
#include <lmem.h>
#include <ec.h>

#ifndef __GEOS__

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
 *  NOTE :  - The newly allocated block should _always_ be zeroed
 *            on return.  Many parts of the engine rely on this to
 *            work properly.
 *          - This function is replaced step by step by GTT_Alloc().
 *
 ******************************************************************/

  EXPORT_FUNC
  TT_Error  TT_Alloc( UShort  Size, void**  P )
  {
    MemHandle  M;

    if ( !P )
      return TT_Err_Invalid_Argument;

    if ( Size > MAX_BLOCK_SIZE )
      return TT_Err_Out_Of_Memory;
  
    if ( Size > 0 )
    {
      M = MemAllocSetOwner( GeodeGetCodeProcessHandle(), 
                            Size,
                            HF_SHARABLE | HF_SWAPABLE, 
                            HAF_ZERO_INIT | HAF_LOCK );

      if ( !M )
        return TT_Err_Out_Of_Memory;
        
      *P = MemDeref( M );
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
    return TT_Err_Ok;
  }

#else  // ifdef __GEOS__


/*******************************************************************
 *
 *  Function    :  GEO_Alloc
 *
 *  Description :  Allocates movable/swappable memory from the heap buffer.
 *
 *  Input  :  Size      size of the memory to be allocated
 *
 *  Output :  Error code.
 *
 *  NOTE :  - The newly allocated block should _always_ be zeroed
 *            on return.  Many parts of the engine rely on this to
 *            work properly.
 *
 ******************************************************************/

  EXPORT_FUNC
  MemHandle GEO_Alloc(  UShort  Size )
  {
    if ( Size > MAX_BLOCK_SIZE )
      return NullHandle;
  
    if ( Size > 0 )
      return MemAllocSetOwner( GeodeGetCodeProcessHandle(), 
                               Size, HF_SHARABLE | HF_SWAPABLE, HAF_ZERO_INIT );

    return NullHandle;
  }


/*******************************************************************
 *
 *  Function    :  GEO_Free
 *
 *  Description :  Releases a previously allocated through GEO_Alloc 
 *                 block of memory.
 *
 *  Input  :  memHandle   handle to memory block
 *
 *  Output :  Always SUCCESS.
 *
 *  Note : The handle must _always_ be set to NullHandle by this function.
 *
 ******************************************************************/
  EXPORT_FUNC
  TT_Error  GEO_Free( MemHandle* memHandle )
  {
    if ( !memHandle )
      return TT_Err_Ok;

    MemFree( memHandle );
    *memHandle = NullHandle;

    return TT_Err_Ok;
  }


#endif
