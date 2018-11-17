/* utilhuge.h
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

#ifndef _UTILHUGE_H
#define _UTILHUGE_H
#ifdef __cplusplus
   extern "C" {
#endif

/* ----------------------------------------------------------------------
 * What follows is functions that allow > 16 bit memory on Win16 and DOS
 * ---------------------------------------------------------------------- */

#if !defined(__WILLOWS) && !defined(JSE_NO_HUGE) && \
    (defined(__JSE_DOS16__) || defined(__JSE_WIN16__))
   #define HUGE_MEMORY  0x7F00L /* if bigger than this then use huge memory */
   ulong HugeFWrite(const void _HUGE_ *ptr,ulong size,ulong n,FILE *stream);
   ulong HugeFRead(void _HUGE_ *ptr,ulong size,ulong n,FILE *stream);
   void _HUGE_ *HugeMemMove( void _HUGE_ *Dst, const void _HUGE_ *Src,
                             ulong ByteCount );
   void _HUGE_ *HugeMemCpy( void _HUGE_ *Dst, const void _HUGE_ *Src,
                            ulong ByteCount );
   void _HUGE_ *HugeMemSet( void _HUGE_ *mem, int val, ulong Count );
   int HugeMemCmp(const void _HUGE_ *Mem1,const void _HUGE_ *Mem2,ulong Len);
   const void _HUGE_ *HugeMemChr(const void _HUGE_ *Mem,int c,ulong Len);
   void _HUGE_ *HugeMalloc(ulong Size);
   void _HUGE_ *HugeReMalloc(void _HUGE_ *OldPtr,ulong NewSize);
   void HugeFree(void _HUGE_ *Ptr);
#elif !defined(JSE_NO_HUGE) && defined(__JSE_MAC__)
   /* All of these functions act the same except for allocating and moving */
#  define HUGE_MEMORY  0x7F00L /* if bigger than this then use huge memory */
#  define HugeFWrite(PTR,SIZE,N,STREAM)  fwrite(PTR,SIZE,N,STREAM)
#  define HugeFRead(PTR,SIZE,N,STREAM)   fread(PTR,SIZE,N,STREAM)
#  define HugeMemMove(DST,SRC,SIZE)      memmove(DST,SRC,SIZE)
#  define HugeMemCpy(DST,SRC,SIZE)       memcpy(DST,SRC,SIZE)
#  define HugeMemSet(MEM,VAL,COUNT)      memset(MEM,VAL,COUNT)
#  define HugeMemCmp(MEM1,MEM2,SIZE)     memcmp(MEM1,MEM2,SIZE)
#  define HugeMemChr(MEM,CHR,SIZE)       memchr(MEM,CHR,SIZE)
   void _HUGE_ *HugeMalloc(size_t Size);
   void _HUGE_ *HugeReMalloc(void _HUGE_ *OldPtr,size_t NewSize);
   void HugeFree(void _HUGE_ *Ptr);
#else
#  define HugeFWrite(PTR,SIZE,N,STREAM)  fwrite(PTR,SIZE,N,STREAM)
#  define HugeFRead(PTR,SIZE,N,STREAM)   fread(PTR,SIZE,N,STREAM)
#  define HugeMemMove(DST,SRC,SIZE)      memmove(DST,SRC,SIZE)
#  define HugeMemCpy(DST,SRC,SIZE)       memcpy(DST,SRC,SIZE)
#  define HugeMemSet(MEM,VAL,COUNT)      memset(MEM,VAL,COUNT)
#  define HugeMemCmp(MEM1,MEM2,SIZE)     memcmp(MEM1,MEM2,SIZE)
#  define HugeMemChr(MEM,CHR,SIZE)       memchr(MEM,CHR,SIZE)
#  define HugeMalloc(SIZE)               jseMustMalloc(void,SIZE)
#  define HugeReMalloc(OLD,SIZE)         jseMustReMalloc(void,OLD,SIZE)
#  define HugeFree(PTR)                  jseMustFree(PTR)
#endif

#define HugePtrIdx(TYPE,PTR,IDX)       ((TYPE _HUGE_ *)PTR+IDX)
#define HugePtrAddition(PTR,OFFSET)    ((ubyte _HUGE_ *)PTR+OFFSET)

#if defined(__JSE_DOS16__) || defined(__JSE_WIN16__)
#  define SegOffPtr(SEGMENT,OFFSET)      MK_FP(SEGMENT,OFFSET)
#elif defined(__JSE_DOS32__)
#  define SegOffPtr(SEGMENT,OFFSET)      \
      ((((uword32)(SEGMENT))<<4)+(uword32)(OFFSET))
#else
#  define SegOffPtr(SEGMENT,OFFSET)      SegOffNotDefined
#endif

#ifdef __cplusplus
}
#endif
#endif
