/* utilhuge.c   Huge memory access routines for systems
 *              needing huge memory
 */

/* (c) COPYRIGHT 1993-98           NOMBAS, INC.
 *                                 64 SALEM ST.
 *                                 MEDFORD, MA 02155  USA
 *
 * ALL RIGHTS RESERVED
 *
 * This software is the property of Nombas, Inc. and is furnished under
 * license by Nombas, Inc.; this software may be used only in accordance
 * with the terms of said license.  This copyright notice may not be removed,
 * modified or obliterated without the prior written permission of Nombas, Inc.
 *
 * This software is a Trade Secret of Nombas, Inc.
 *
 * This software may not be copied, transmitted, provided to or otherwise made
 * available to any other person, company, corporation or other entity except
 * as specified in the terms of said license.
 *
 * No right, title, ownership or other interest in the software is hereby
 * granted or transferred.
 *
 * The information contained herein is subject to change without notice and
 * should not be construed as a commitment by Nombas, Inc.
 */

#include "jseopt.h"
#include "utilhuge.h"
#include "jsemem.h"
#if defined(__WATCOMC__)
   #include "i86.h"
#endif
#if defined(__JSE_MAC__)
   #include <memory.h>
#endif

#ifdef HUGE_MEMORY

#if defined(__JSE_DOS16__) || defined(__JSE_WIN16__)
#if !defined(__JSE_GEOS__)
#include <dos.h>
#endif

#define  MAX_BLOCKSIZE  0x4000   /* break huge operations into this size */
#define LIMITED_SIZE(Size32)  (Size32 < MAX_BLOCKSIZE ? (uword16)Size32 : \
                               MAX_BLOCKSIZE)
#define MAX_SAME_SEGMENT_INCREMENT(Ptr) \
     ( ((uword16)((uword32)Ptr)) ? ~((uword16)((uword32)Ptr)) + 1 : 0xFFFF )
#define MAX_SAME_SEGMENT_DECREMENT(Ptr) \
     ( ((uword16)((uword32)Ptr)) ? (uword16)((uword32)Ptr) : 0xFFFF )

   static uword16 NEAR_CALL
MinSize(uword16 Size1,uword16 Size2)
{
   return Size1 < Size2 ? Size1 : Size2;
}


   static ulong NEAR_CALL
HugeFReadOrFWrite(jsebool FRead/*else FWrite*/,
                  void _HUGE_ *ptr,ulong size,ulong n,FILE *stream)
{
   uword32 Count = size * n;
   uword32 Total = 0;
   uword16 Result, Wanted;
   ubyte _HUGE_ * NextPtr = (ubyte _HUGE_ *)ptr;
   while ( Count )
   {
      Wanted =
         MinSize(LIMITED_SIZE(Count),MAX_SAME_SEGMENT_INCREMENT(NextPtr));
      Result = FRead
             ? fread((void _FAR_ *)NextPtr,1,Wanted,stream)
             : fwrite((const void _FAR_ *)NextPtr,1,Wanted,stream);
      Total += Result;
      if ( Result != Wanted )
         break;
      Count -= Wanted;
      NextPtr += Wanted;
   } /* endwhile */
   /* return count modified by size */
   return( Total / size );
}

   ulong
HugeFWrite(const void _HUGE_ *ptr,ulong size,ulong n,FILE *stream)
{
   return HugeFReadOrFWrite(False,(void _HUGE_ *)ptr,size,n,stream);
}

   ulong
HugeFRead(void _HUGE_ *ptr,ulong size,ulong n,FILE *stream)
{
   return HugeFReadOrFWrite(True,ptr,size,n,stream);
}

#if defined(__cplusplus)
extern "C" {
#endif
extern void pascal near MemCpyBottomUp(void _FAR_ *dst,
                                       const void _FAR_ *src,
                                       uword16 ByteCount);
extern void pascal near MemCpyTopDown(void _FAR_ *dst,
                                      const void _FAR_ *src,
                                      uword16 ByteCount);
#if defined(__cplusplus)
}
#endif

   void _HUGE_ *
HugeMemCpy( void _HUGE_ *Dst, const void _HUGE_ *Src, ulong ByteCount )
     /* copies from low addresses to high addresses, incrementing */
{
   if ( ByteCount )
   {
      ubyte _HUGE_ *DstPtr = (ubyte _HUGE_ *)Dst;
      ubyte _HUGE_ *SrcPtr = (ubyte _HUGE_ *)Src;
      uword16 ChunkSize;
      for ( ; ; )
      {
         ChunkSize = MinSize(LIMITED_SIZE(ByteCount),
             MinSize(MAX_SAME_SEGMENT_INCREMENT(DstPtr),
                     MAX_SAME_SEGMENT_INCREMENT(SrcPtr)));
         assert( ChunkSize );
         MemCpyBottomUp((void _FAR_ *)DstPtr,
                        (const void _FAR_ *)SrcPtr,ChunkSize);
         if ( !(ByteCount -= ChunkSize) )
            break;
         DstPtr += ChunkSize;
         SrcPtr += ChunkSize;
      } /* endfor */
   } /* endif */
   return Dst;
}

#define NORMALIZED_
   void _HUGE_ *
HugeMemMove( void _HUGE_ *Dst, const void _HUGE_ *Src, ulong ByteCount )
{
   /* move from bottom up or top down depending on whether moving
    * in overlapping memory down or up.  The following comparison does
    * a straight uwrod32 compare which is OK because first it doesn't
    * matter which direction if memory doesn't overlap, and second
    * if memory does overlap then it is from the same base pointer
    * and the compiler handled huge pointer addition such that no
    * two segment addresses cover the same offset range
    */
   ubyte _HUGE_ *DstPtr;
   ubyte _HUGE_ *SrcPtr;
   uword16 ChunkSize;

   if ( (uword32)Dst <= (uword32)Src )
      return HugeMemCpy(Dst,Src,ByteCount);

   /* copy starting chunks at the end */
   DstPtr = (ubyte _HUGE_ *)Dst + ByteCount;
   SrcPtr = (ubyte _HUGE_ *)Src + ByteCount;
   while ( ByteCount )
   {
      ChunkSize = MinSize(LIMITED_SIZE(ByteCount),
                          MinSize(MAX_SAME_SEGMENT_DECREMENT(DstPtr),
                                  MAX_SAME_SEGMENT_DECREMENT(SrcPtr)));
      assert( ChunkSize );
      MemCpyTopDown((void _FAR_ *)(DstPtr -= ChunkSize),
                    (const void _FAR_ *)(SrcPtr -= ChunkSize),ChunkSize);
      ByteCount -= ChunkSize;
   } /* endwhile */
   return Dst;
}

   void _HUGE_ *
HugeMemSet( void _HUGE_ *mem, int val, ulong ByteCount )
{
   if ( ByteCount )
   {
      ubyte _HUGE_ *MemPtr = (ubyte _HUGE_ *)mem;
      uword16 ChunkSize;
      for ( ; ; )
      {
         ChunkSize = MinSize(LIMITED_SIZE(ByteCount),
                             MAX_SAME_SEGMENT_INCREMENT(MemPtr));
         assert( ChunkSize );
         memset((void _FAR_ *)MemPtr,val,ChunkSize);
         if ( !(ByteCount -= ChunkSize) )
            break;
         MemPtr += ChunkSize;
      } /* endfor */
   } /* endif */
   return mem;
}

   int
HugeMemCmp(const void _HUGE_ *Mem1,const void _HUGE_ *Mem2,ulong Len)
{
   int result = 0;
   if ( Len )
   {
      ubyte _HUGE_ *Mem1Ptr = (ubyte _HUGE_ *)Mem1;
      ubyte _HUGE_ *Mem2Ptr = (ubyte _HUGE_ *)Mem2;
      uword16 ChunkSize;
      for ( ; ; )
      {
         ChunkSize = MinSize(LIMITED_SIZE(Len),
                             MinSize(MAX_SAME_SEGMENT_INCREMENT(Mem1Ptr),
                                     MAX_SAME_SEGMENT_INCREMENT(Mem2Ptr)));
         assert( ChunkSize );
         if ( 0 != (result = memcmp((const void _FAR_ *)Mem1Ptr,
                                    (const void _FAR_ *)Mem2Ptr,ChunkSize))
           || !(Len -= ChunkSize) )
            break;
         Mem1Ptr += ChunkSize;
         Mem2Ptr += ChunkSize;
      } /* endfor */
   } /* endif */
   return result;
}

        const void _HUGE_ *
HugeMemChr(const void _HUGE_ *Mem,int c,ulong Len)
{
   const void _HUGE_ *Result = NULL;
   if ( Len )
   {
      ubyte _HUGE_ *MemPtr = (ubyte _HUGE_ *)Mem;
      uword16 ChunkSize;
      for ( ; ; )
      {
         ChunkSize = MinSize(LIMITED_SIZE(Len),
                             MAX_SAME_SEGMENT_INCREMENT(MemPtr));
         assert( ChunkSize );
                        if ( NULL != (Result =
                   memchr((const void _FAR_ *)MemPtr,c,ChunkSize))
           || !(Len -= ChunkSize) )
            break;
         MemPtr += ChunkSize;
      } /* endfor */
   } /* endif */
        return Result;
}


#if defined(__JSE_DOS16__)

struct HugeMemory {
   uword32  Size;    /* does not include size of this structure */
};

   void _HUGE_ *
HugeMalloc(ulong Size)
{
   uword16 Paragraphs;
   union REGS inreg, outreg;
   struct HugeMemory _FAR_ *HugeMem;

   assert( sizeof(struct HugeMemory) < 16 );

   /* modify size to fit a full paragraph */
   Paragraphs = (uword16)((Size + 15) >> 4);

   /* allocate memory from DOS */
   inreg.h.ah = 0x48;
   inreg.x.bx = Paragraphs + 1;
   intdos(&inreg,&outreg);
   if ( outreg.x.cflag )
      /* unable to allocate. Dang! */
      jseInsufficientMemory();

   HugeMem = (struct HugeMemory _FAR_ *)SegOffPtr(outreg.x.ax,0);
   HugeMem->Size = Size;
   return SegOffPtr(outreg.x.ax+1,0);
}

   void
HugeFree(void _HUGE_ *Ptr)
{
   struct SREGS sregs;
   union REGS inreg, outreg;

   assert( Ptr );
   assert( 0 == FP_OFF(Ptr) );

   segread(&sregs);
   inreg.h.ah = 0x49;
   sregs.es = FP_SEG(Ptr) - 1;
   int86x(0x21,&inreg,&outreg,&sregs);
}

   void _HUGE_ *
HugeReMalloc(void _HUGE_ *OldPtr,ulong NewSize)
{
   uword16 OldSegment;
   struct HugeMemory _FAR_ *OldHugeMem;
   uword16 Paragraphs;
   union REGS inreg, outreg;
   void _HUGE_ *NewPtr;
   struct SREGS sregs;

   assert( OldPtr );
   assert( 0 == FP_OFF(OldPtr) );

   OldSegment = FP_SEG(OldPtr) - 1;
   OldHugeMem = (struct HugeMemory _FAR_ *)SegOffPtr(OldSegment,0);
   Paragraphs = (uword16)((NewSize + 15) >> 4);

   inreg.h.ah = 0x4A;
   inreg.x.bx = Paragraphs + 1;
   segread(&sregs);
   sregs.es = OldSegment;
   int86x(0x21,&inreg,&outreg,&sregs);
   if ( !outreg.x.cflag )
   {
      /* success, no problem, whoopee */
      OldHugeMem->Size = NewSize;
      return OldPtr;
   }

   /* here if memory failed, and so try to allocate a new huge
    * block and copy to there.  If cannot then failure.
    */
   NewPtr = HugeMalloc(NewSize);
   HugeMemCpy(NewPtr,OldPtr,OldHugeMem->Size);
   HugeFree(OldPtr);
   return NewPtr;
}

#elif defined(__JSE_WIN16__)

struct HugeMemory {
   HGLOBAL  handle;
   ubyte     filler[2];  /* make size end on 4-boundary */
};

   static void _HUGE_ * NEAR_CALL
LockHandleAndGetPtr(HGLOBAL handle)
{
   struct HugeMemory _FAR_ * HugeMem;

   assert( 0 == (sizeof(struct HugeMemory) % 4) );
      /* avoid weird segment wraps */
   if ( !handle )
      /* unable to allocate. Dang! */
      jseInsufficientMemory();
   HugeMem = (struct HugeMemory _FAR_ *)GlobalLock(handle);
   assert( HugeMem );
   HugeMem->handle = handle;
   assert( (ubyte _HUGE_ *)((ubyte _FAR_ *)HugeMem + sizeof(struct HugeMemory)) ==
           ((ubyte _HUGE_ *)HugeMem + sizeof(struct HugeMemory)) );
   return((ubyte _FAR_ *)HugeMem + sizeof(struct HugeMemory));
}

   static HGLOBAL NEAR_CALL
GetGHandleFromPtr(void _HUGE_ *Ptr)
{
   struct HugeMemory _FAR_ *HugeMem;
   HugeMem = (struct HugeMemory _FAR_ *)(((ubyte _FAR_ *)Ptr) -
                                         sizeof(struct HugeMemory));
   return HugeMem->handle;
}

   void _HUGE_ *
HugeMalloc(ulong Size)
{
   return LockHandleAndGetPtr(GlobalAlloc(GMEM_MOVEABLE,Size+
                                          sizeof(struct HugeMemory)));
}

   void
HugeFree(void _HUGE_ *Ptr)
{
   HGLOBAL handle = GetGHandleFromPtr(Ptr);
   #if defined(NDEBUG)
      GlobalUnlock(handle);
      GlobalFree(handle);
   #else
      assert( 0 == GlobalUnlock(handle) );
      assert( NULL == GlobalFree(handle) );
   #endif
}

   void _HUGE_ *
HugeReMalloc(void _HUGE_ *OldPtr,ulong NewSize)
{
   HGLOBAL handle;

   assert( OldPtr );
   handle = GetGHandleFromPtr(OldPtr);
   #if defined(NDEBUG)
      GlobalUnlock(handle);
   #else
      assert( 0 == GlobalUnlock(handle) );
   #endif
   return LockHandleAndGetPtr(GlobalReAlloc(handle,NewSize+
                sizeof(struct HugeMemory),GMEM_MOVEABLE));
}

#else

   #error No HugeMalloc, etc... for this model

#endif

#elif defined(__JSE_MAC__)

static Handle
GetHandleFromPtr( void _HUGE_ *ptr )
{
  return (Handle) (*(ubyte**)((ubyte *)ptr - sizeof(Handle)));
}

static void *
SetHandleAndGetPtr( Handle handle )
{
  BlockMove( &handle, *handle, sizeof(Handle));
  return (void *) ((*handle) + 4);
}

void _HUGE_ *
HugeMalloc(size_t size)
{
  OSErr result;

  Handle handle = TempNewHandle( (long) (size + sizeof(Handle)), &result );
     /* Get from system memory */

  if( result != noErr )
    /* Not enough memory */
    jseInsufficientMemory();

  assert( handle != NULL );
  HLock( handle );

  return SetHandleAndGetPtr( handle );
}

void _HUGE_ *HugeReMalloc(void _HUGE_ *ptr,size_t NewSize)
{
  Handle handle = GetHandleFromPtr( ptr );

  HUnlock( handle );

  SetHandleSize( handle, (long) (NewSize + sizeof(Handle)) );
  if (MemError() != noErr)
  {
    assert( MemError() == memFullErr );
       /* Otherwise some unforseen error occurred */
    jseInsufficientMemory();
  }

  HLock( handle );
  return SetHandleAndGetPtr( handle );
}

void HugeFree(void _HUGE_ *ptr)
{
  Handle handle = GetHandleFromPtr( ptr );

  HUnlock( handle );

  DisposeHandle( handle );
}

#endif

#endif
