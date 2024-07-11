/*******************************************************************
 *
 *  ttmemory.h                                               1.2
 *
 *    Memory management component (specification).
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
 *  Changes between 1.2 and 1.1:
 *
 *  - the font pool is gone!  All allocations are now performed
 *    with malloc() and free().
 *
 *  - introduced the FREE() macro and the Free() function for
 *    future use in destructors.
 *
 ******************************************************************/

#ifndef TTMEMORY_H
#define TTMEMORY_H

#include "ttconfig.h"
#include "tttypes.h"
#include <string.h>
#include <heap.h>


#ifdef __cplusplus
  extern "C" {
#endif

#define MAX_BLOCK_SIZE  32000

#define MEM_Set( dest, byte, count )  memset( dest, byte, count )

#ifdef __GEOS__
#define MEM_Cmp( left, right, count )  memcmp( left, right, count )
#endif  /* __GEOS__ */

#ifdef HAVE_MEMCPY
#define MEM_Copy( dest, source, count )  memcpy( dest, source, count )
#else
#define MEM_Copy( dest, source, count )  bcopy( source, dest, count )
#endif

#ifdef HAVE_MEMMOVE
#define MEM_Move( dest, source, count )  memmove( dest, source, count )
#else
#define MEM_Move( dest, source, count )  bcopy( source, dest, count )
#endif


#define MEM_Alloc( _pointer_, _size_ ) \
  TT_Alloc( _size_, (void**)&(_pointer_) )

#define ALLOC( _pointer_, _size_ ) \
  ( ( error = MEM_Alloc( _pointer_, _size_ ) ) != TT_Err_Ok )

#define ALLOC_ARRAY( _pointer_, _count_, _type_ ) \
  ( ( error = MEM_Alloc( _pointer_, \
                         (_count_) * sizeof ( _type_ ) ) ) != TT_Err_Ok )

#define FREE( _pointer_ ) \
  TT_Free( (void**)&(_pointer_) )


  /* Allocate a block of memory of 'Size' bytes from the heap, and */
  /* sets the pointer '*P' to its address.  If 'Size' is 0, or in  */
  /* case of error, the pointer is always set to NULL.             */

  EXPORT_DEF
  TT_Error  TT_Alloc( UShort  Size, void**  P );


  /* Releases a block that was previously allocated through Alloc. */
  /* Note that the function returns successfully when P or *P are  */
  /* already NULL.  The pointer '*P' is set to NULL on exit in     */
  /* case of success.                                              */

  EXPORT_DEF
  TT_Error  TT_Free( void**  P );


  #define GEO_MEM_ALLOC( _memHandle_, _size_ ) \
    GEO_Alloc( _size_, (MemHandle*)&_memHandle_ )

  #define GEO_ALLOC_ARRAY( _memHandle_, _count_, _type_ ) \
    ( ( error = GEO_MEM_ALLOC( _memHandle_, \
                              (_count_) * sizeof ( _type_ ) ) ) != TT_Err_Ok )

  #define GEO_FREE( _memHandle_ ) \
    GEO_Free( (MemHandle*)&_memHandle_ )

  #define GEO_LOCK( _memHandle_ ) \
    (( _memHandle_ ) != NullHandle ? MemLock( _memHandle_ ) : NULL )

  #define GEO_UNLOCK( _memHandle_ ) \
    (( _memHandle_ ) != NullHandle ? MemUnlock( _memHandle_ ) : (void)0 )


  /* Allocate a movable and swapable block of memory of 'Size' bytes */
  /* from the heap, and return its handle. If 'Size' is 0, or in     */
  /* case of error, the returned handle is always a NullHandle.      */

  EXPORT_DEF
  TT_Error GEO_Alloc(  UShort  Size, MemHandle*  M );


  /* Releases a block that was previously allocated through GEO_Alloc. */
  /* Note that the function returns successfully when MemHandle is     */
  /* already NullHandle. The memHandle is set to NullHandle on exit in */
  /* case of success.                                                  */

  EXPORT_DEF
  TT_Error  GEO_Free( MemHandle*  memHandle );
  

  LOCAL_DEF TT_Error  TTMemory_Init( void );
  LOCAL_DEF TT_Error  TTMemory_Done( void );


#ifdef __cplusplus
  }
#endif

#endif /* TTMEMORY_H */


/* END */
